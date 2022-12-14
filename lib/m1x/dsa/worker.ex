defmodule Dsa.Worker do
  defstruct battle_id: nil,
            socket: nil,
            room_id: nil,
            map_id: nil,
            members: %{},
            infos: %{},
            ready_states: %{},
            host: nil,
            out_port: nil,
            in_port: nil,
            pid: nil,
            os_pid: nil,
            ref: nil,
            ds_path: nil

  use Common
  use GenServer

  @moduledoc """
  ./ds -game_mapId <mapid> -direct_test 1 -playerCnt 10 -game_battleid <battleId>  -net_inPort <inPort>  -net_outPort <outPort> -room_id <room_id>
  """

  alias __MODULE__, as: M

  def pid(battle_id) do
    :global.whereis_name(name(battle_id))
  end

  def name(battle_id) do
    :"Battle_#{battle_id}"
  end

  def via(battle_id) do
    {:global, name(battle_id)}
    # {:via, Horde.Registry, {Matrix.RoleRegistry, role_id}}
  end

  def child_spec([battle_id | _] = args) do
    %{
      id: "Battle_#{battle_id}",
      start: {__MODULE__, :start_link, [args]},
      shutdown: 10_000,
      restart: :transient
    }
  end

  def send_to_ds(battle_id, msg) do
    cast(battle_id, {:ds_msg, msg})
  end

  def start_link([battle_id | _] = args) do
    GenServer.start_link(__MODULE__, args, name: via(battle_id))
  end

  @impl true
  def init([battle_id, socket, room_id, map_id, members, infos, host, out_port, dsa_port]) do
    game_mapId = map_id
    direct_test = 0
    game_battleid = battle_id
    net_outPort = out_port
    net_inPort = out_port + 1
    net_dsaPort = dsa_port

    args =
      for {k, v} <- ~m{game_mapId,direct_test,game_battleid,net_outPort,net_inPort,net_dsaPort} do
        ["-#{k}", "#{v}"]
      end
      |> Enum.concat()

    # Logger.info(args)
    ds_path =
      System.user_home!()
      |> File.ls!()
      |> Enum.filter(&String.starts_with?(&1, "ds"))
      |> Enum.sort(:desc)
      |> List.first()

    {pid, ref} =
      Process.spawn(
        fn ->
          Logger.debug("execute cmd: #{System.user_home!()}/#{ds_path}/ds #{inspect(args)}")
          System.cmd("#{System.user_home!()}/#{ds_path}/ds", args)
        end,
        [:monitor]
      )

    ready_states =
      for {_, v} <- members, v != nil, into: %{} do
        {v, false}
      end

    state =
      ~M{%M battle_id,socket,room_id, map_id, members,infos,ready_states, host, out_port,in_port: net_inPort,pid, ref}

    {:ok, state}
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, ~M{%M ref,battle_id,room_id} = state) do
    Dsa.Svr.end_game([battle_id, room_id])
    {:stop, :normal, state}
  end

  @impl true
  def handle_cast({:msg, msg}, state) do
    state = handle(state, msg)
    {:noreply, state}
  end

  # TODO delete when test finish
  def handle_cast(
        {:dc2ds, ~M{%Pbm.Dsa.QuitGame2C battle_id, player_id, reason}},
        ~M{%M room_id} = state
      ) do
    ~M{%Pbm.Dsa.PlayerQuit2S battle_id, player_id, reason}
    |> PB.encode!()
    |> IO.iodata_to_binary()
    |> (&%Dc.RoomMsg2S{room_id: room_id, data: &1}).()
    |> Dsa.Svr.send2dc()

    {:noreply, state}
  end

  def handle_cast({:dc2ds, msg}, state) do
    send2ds(state, msg)
    {:noreply, state}
  end

  def cast(battle_id, msg) when is_integer(battle_id) do
    with pid when is_pid(pid) <- name(battle_id) |> :global.whereis_name() do
      cast(pid, msg)
    else
      _ ->
        {:error, :battle_not_exist}
    end
  end

  def cast(pid, msg) when is_pid(pid) do
    pid |> GenServer.cast(msg)
  end

  def call(battle_id, msg) when is_integer(battle_id) do
    with pid when is_pid(pid) <- name(battle_id) |> :global.whereis_name() do
      call(pid, msg)
    else
      _ ->
        {:error, :battle_not_exist}
    end
  end

  def call(pid, msg) when is_pid(pid) do
    pid |> GenServer.call(msg)
  end

  def handle(~M{%M room_id,battle_id} = state, ~M{%Pbm.Dsa.Start2S pid,result}) do
    if result == 0 do
      Logger.debug("the battle os pid is #{pid},battle_id: #{battle_id}")

      ~M{%Dc.BattleStarted2S room_id,battle_id}
      |> Dsa.Svr.send2dc()

      ~M{%M state| os_pid: pid}
    else
      Logger.warning("battle start fail!")
      Dsa.Svr.end_game([battle_id, room_id])
      state
    end
  end

  def handle(~M{%M } = state, ~M{%Pbm.Dsa.BattleInfo2S battle_id} = _msg) do
    battle_info = %Pbm.Dsa.BattleInfo{
      auto_armor: true,
      kill_award_double: false,
      init_hp: 100,
      max_hp: 100,
      gravity_rate: 1,
      friction_rate: 1,
      head_shoot_only: false,
      stat_trak: false,
      game_level: 1,
      win_type: :kills,
      win_value: 50
    }

    state
    |> send2ds(~M{%Pbm.Dsa.BattleInfo2C battle_id,battle_info})
    |> send_role_info()
  end

  def handle(~M{%M ready_states} = state, ~M{%Pbm.Dsa.RoleReady2S player_id}) do
    ready_states = Map.put(ready_states, player_id, true)
    ~M{state| ready_states} |> check_start()
  end

  def handle(state, ~M{%Pbm.Dsa.Heartbeat2S }) do
    state
  end

  # TODO ??????????????????????????????????????????????????????
  def handle(~M{%M room_id} = state, ~M{%Pbm.Dsa.PlayerQuit2S } = msg) do
    msg
    |> PB.encode!()
    |> IO.iodata_to_binary()
    |> (&%Dc.RoomMsg2S{room_id: room_id, data: &1}).()
    |> Dsa.Svr.send2dc()

    state
  end

  def handle(~M{%M room_id} = state, ~M{%Pbm.Dsa.GameStatis2S } = msg) do
    msg
    |> PB.encode!()
    |> IO.iodata_to_binary()
    |> (&%Dc.RoomMsg2S{room_id: room_id, data: &1}).()
    |> Dsa.Svr.send2dc()

    state
  end

  def handle(state, msg) do
    Logger.warn("unhandle dsa msg #{inspect(msg)}")
    state
  end

  defp send2ds(~M{%M socket,in_port} = state, msg) do
    Logger.info("dsa send to ds : #{inspect(msg)}")
    :ok = :gen_udp.send(socket, {127, 0, 0, 1}, in_port, PB.encode!(msg))
    state
  end

  defp send_role_info(~M{%M members,infos} = state) do
    members
    |> Enum.each(fn {pos, id} ->
      if id != nil do
        ~M{%Dc.RoleInfo role_name,level,avatar_id,robot,robot_type} = infos[id]

        camp_id =
          cond do
            # T
            pos in [0, 1, 2, 3, 4] -> 1
            # CT
            pos in [5, 6, 7, 8, 9] -> 2
            # Observer
            true -> 8
          end

        msg =
          %Pbm.Dsa.RoleBaseInfo{
            uid: id,
            name: role_name,
            group_id: camp_id,
            camp_id: camp_id,
            avatar: avatar_id,
            level: level
          }
          |> (&%Pbm.Dsa.Role{
                replace_uid: id,
                ai_property_type: 1,
                robot: robot,
                robot_type: robot_type,
                base_info: &1
              }).()
          |> (&%Pbm.Dsa.RoleInfo2C{role: &1}).()

        send2ds(state, msg)
      end
    end)

    state
  end

  defp check_start(~M{%M room_id,battle_id,out_port,host,map_id,ready_states} = state) do
    if ready_states |> Map.values() |> Enum.all?() do
      ~M{%Pbm.Room.StartGame2C battle_id, host, port: out_port,map_id}
      |> PB.encode!()
      |> IO.iodata_to_binary()
      |> (&%Dc.RoomMsg2S{room_id: room_id, data: &1}).()
      |> Dsa.Svr.send2dc()
    end

    state
  end
end
