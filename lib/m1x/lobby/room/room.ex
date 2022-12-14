defmodule Lobby.Room do
  defstruct room_id: 0,
            room_type: 0,
            owner_id: nil,
            status: 0,
            map_id: 0,
            members: %{},
            member_num: 0,
            create_time: 0,
            password: "",
            last_game_time: 0,
            room_name: nil,
            mode: nil,
            lv_limit: nil,
            round_total: nil,
            round_time: nil,
            enable_invite: true,
            # ext 自定义扩展参数
            ext: nil

  use Common
  alias __MODULE__, as: M

  @loop_interval 10_000
  @idle_time 3_600

  @positions [0, 5, 1, 6, 2, 7, 3, 8, 4, 9, 10, 11, 12]

  @room_type_free 1
  @room_type_match 2

  @status_idle 0
  @status_battle 1

  def init([room_id, room_type = @room_type_free, role_ids, map_id, password]) do
    init([room_id, room_type, role_ids, map_id, password, nil])
  end

  def init([room_id, room_type, role_ids, map_id, password, args]) do
    owner_id = List.first(role_ids)
    Logger.debug("Room.Svr room_id: [#{room_id}] owenr_id: [#{owner_id}]  start")
    :pg.join(M, self())
    create_time = Util.unixtime()
    last_game_time = create_time

    password =
      if String.trim(password) != "" do
        Util.md5("#{map_id}@#{password}") |> Base.encode16(case: :lower)
      else
        ""
      end

    state =
      if room_type == @room_type_free do
        ~M{room_name,lv_limit,round_total,round_time,enable_invite} = args

        ~M{%M room_id,room_type,map_id,password,create_time,last_game_time,owner_id,room_name,lv_limit,round_total,round_time,enable_invite}
        |> do_join(role_ids)
      else
        ~M{ext,members} = args

        ~M{%M room_id,room_type,map_id,password,create_time,last_game_time,owner_id,ext,members}
        |> do_join(role_ids)
      end

    :ets.insert(Room, {room_id, state})
    Process.send_after(self(), :secondloop, @loop_interval)
    state
  end

  def to_common(%Lobby.Room{} = data) do
    data = Map.from_struct(data)
    data = %Pbm.Room.Room{}.__struct__ |> struct(data)
    data
  end

  def secondloop(~M{%M room_id,member_num,last_game_time} = state) do
    now = Util.unixtime()

    if member_num == 0 or now >= last_game_time + @idle_time do
      self() |> Process.send(:shutdown, [:nosuspend])
    else
      Process.send_after(self(), :secondloop, @loop_interval)

      if dirty?() do
        :ets.insert(Room, {room_id, state})
        set_dirty(false)
      end
    end

    state
  end

  def set_map(~M{%owner_id} = state, [role_id, map_id]) do
    if role_id != owner_id do
      throw("你不是房主")
    end

    %Pbm.Room.SetRoomMap2C{role_id: role_id, map_id: map_id} |> broad_cast()
    ~M{state|map_id} |> sync() |> ok()
  end

  def kick(~M{%M owner_id,members,member_num} = state, [f_role_id, t_role_id]) do
    if f_role_id != owner_id do
      throw("你不是房主")
    end

    if not :ordsets.is_element(t_role_id, role_ids()) do
      throw("对方不在房间")
    end

    members = for {k, v} <- members, v != t_role_id, into: %{}, do: {k, v}
    member_num = member_num - 1
    del_role_id(t_role_id)
    %Pbm.Room.Kick2C{role_id: t_role_id} |> broad_cast()
    Role.Svr.cast(t_role_id, {:kicked_from_room, f_role_id})
    ~M{state|members,member_num} |> sync() |> ok()
  end

  def change_pos(~M{%M members} = state, [role_id, position]) do
    if position not in @positions do
      throw("不是合法的位置")
    end

    with nil <- members[position] do
      members =
        members |> Map.filter(fn {_key, val} -> val != role_id end) |> Map.put(position, role_id)

      %Pbm.Room.ChangePosResult2C{members: members} |> broad_cast()
      ~M{state|members} |> sync |> ok()
    else
      t_role_id ->
        %Pbm.Room.ChangePosReq2C{role_id: role_id} |> Role.Misc.send_to(t_role_id)
        Process.put({:change_pos_req, role_id}, {t_role_id, Util.unixtime()})
        state |> ok()
    end
  end

  def change_pos_reply(~M{%M members} = state, [role_id, f_role_id, accept]) do
    with {^role_id, _timestamp} <- Process.get({:change_pos_req, f_role_id}) do
      Process.delete({:change_pos_req, f_role_id})

      if accept do
        members =
          for {k, v} <- members, into: %{} do
            v = (v == role_id && f_role_id) || (v == f_role_id && role_id) || v
            {k, v}
          end

        %Pbm.Room.ChangePosResult2C{members: members} |> broad_cast()
        ~M{state|members} |> sync |> ok()
      else
        %Pbm.Room.ChangePosRefuse2C{role_id: role_id} |> Role.Misc.send_to(f_role_id)
        state |> ok()
      end
    else
      _ ->
        state |> ok()
    end
  end

  def join(~M{%M room_id,password,member_num,map_id,status} = state, [role_id, tpassword]) do
    tpassword = String.trim(tpassword)
    tpassword = Util.md5("#{map_id}@#{tpassword}") |> Base.encode16(case: :lower)
    if password != "" && password != tpassword, do: throw("房间密码不正确")
    if member_num >= length(@positions), do: throw("房间已满")
    if status == @status_battle, do: throw("房间在战斗中")
    state = do_join(state, [role_id])
    ~M{%Pbm.Room.Join2C role_id, room_id} |> broad_cast()
    state |> sync() |> ok()
  end

  defp do_join(state, []), do: state

  defp do_join(~M{%M members, member_num} = state, [role_id | t]) do
    members =
      if Enum.find_value(members, &(elem(&1, 1) == role_id)) do
        members
      else
        pos = find_free_pos(state)
        members |> Map.put(pos, role_id)
      end

    add_role_id(role_id)
    member_num = member_num + 1

    ~M{state | member_num ,members}
    |> do_join(t)
  end

  @doc """
  开始游戏回调
  """
  def start_game(~M{%M room_id,owner_id, map_id,members,room_type,ext,status} = state, role_id) do
    if role_id != owner_id, do: throw("你不是房主")
    if status == @status_battle, do: throw("战斗未结束")
    if check_before_start(members) == false, do: throw("人数不足，无法开始游戏")

    with :ok <- Dc.Manager.start_game([map_id, room_id, members]) do
      if room_type == @room_type_match do
        ~M{team_ids} = ext
        Enum.each(team_ids, &Team.Svr.begin_battle(&1, []))
      end

      Map.values(members)
      |> Enum.each(&Role.Svr.role_status_change(&1, {:battle_start, room_type}))

      ~M{state|status: @status_battle} |> ok()
    else
      {:error, :no_dsa_available} ->
        throw(:no_dsa_available)
    end
  end

  def exit_room(~M{%M members,member_num,owner_id} = state, role_id) do
    if not :ordsets.is_element(role_id, role_ids()) do
      {:ok, state}
    else
      members =
        for {k, v} <- members, v != role_id, into: %{} do
          {k, v}
        end

      member_num = member_num - 1
      del_role_id(role_id)
      ~M{%Pbm.Room.Exit2C role_id} |> broad_cast()

      owner_id =
        if role_id == owner_id do
          role_ids() |> Util.rand_list() || 0
        else
          owner_id
        end

      if member_num == 0 do
        self() |> Process.send(:shutdown, [:nosuspend])
      end

      ~M{state| members,member_num,owner_id} |> sync() |> ok()
    end
  end

  def ds_msg(
        ~M{%M room_type,ext,members} = state,
        ~M{%Pbm.Dsa.GameStatis2S battle_id, battle_result} = msg
      ) do
    Logger.debug("room receive ds msg #{inspect(msg)}")

    ~M{%Pbm.Battle.BattleResult2C battle_id,battle_result}
    |> broad_cast()

    if room_type == @room_type_match do
      ~M{team_ids} = ext
      Enum.each(team_ids, &Team.Svr.battle_closed(&1, [:battle_finish]))

      ## 匹配临时房间战斗结束关闭
      self() |> Process.send(:shutdown, [:nosuspend])
    end

    Map.values(members)
    |> Enum.each(&Role.Svr.role_status_change(&1, {:battle_closed, room_type, :battle_finish}))

    ~M{state|status: @status_idle} |> ok()
  end

  def ds_msg(~M{%M room_type,ext,members} = state, ~M{%Dc.BattleEnd2S } = msg) do
    Logger.debug("room receive ds msg #{inspect(msg)}")

    if room_type == @room_type_match do
      ~M{team_ids} = ext
      Enum.each(team_ids, &Team.Svr.battle_closed(&1, [:ds_down]))

      ## 匹配临时房间战斗结束关闭
      self() |> Process.send(:shutdown, [:nosuspend])
    end

    Map.values(members)
    |> Enum.each(&Role.Svr.role_status_change(&1, {:battle_closed, room_type, :ds_down}))

    ~M{state|status: @status_idle} |> ok()
  end

  def ds_msg(~M{%M room_type,ext,members} = state, ~M{%Dc.StartBattleFail2S }) do
    if room_type == @room_type_match do
      ~M{team_ids} = ext
      Enum.each(team_ids, &Team.Svr.battle_closed(&1, [:start_fail]))

      ## 匹配临时房间战斗结束关闭
      self() |> Process.send(:shutdown, [:nosuspend])
    end

    Map.values(members)
    |> Enum.each(&Role.Svr.role_status_change(&1, {:battle_closed, room_type, :start_fail}))

    ~M{state|status: @status_idle} |> ok()
  end

  def ds_msg(~M{%M members } = state, ~M{%Dc.BattleStarted2S } = msg) do
    for {_, role_id} <- members do
      Role.Svr.execute(role_id, &Role.Mod.Battle.on_battle_started/2, msg)
    end

    {:ok, state}
  end

  def ds_msg(~M{%M room_type,room_id} = state, ~M{%Pbm.Dsa.PlayerQuit2S player_id} = msg) do
    Logger.debug("room(#{room_type}-#{room_id}) receive ds msg #{inspect(msg)}")
    # TODO msg的数据有可能是重复的，所以修改状态前必须保证是同一场战斗
    Role.Svr.role_status_change(player_id, msg)
    {:ok, state}
  end

  def ds_msg(state, msg) do
    broad_cast(msg)
    {:ok, state}
  end

  defp find_free_pos(state, poses \\ @positions)
  defp find_free_pos(_state, []), do: throw("没有空余的位置了")

  defp find_free_pos(~M{%M members} = state, [pos | t]) do
    if members[pos] == nil do
      pos
    else
      find_free_pos(state, t)
    end
  end

  def set_dirty(dirty) do
    Process.put({M, :dirty}, dirty)
  end

  defp dirty?() do
    Process.get({M, :dirty}, false)
  end

  defp role_ids() do
    Process.get({M, :role_ids}, [])
  end

  defp set_role_ids(ids) do
    Process.put({M, :role_ids}, ids)
  end

  defp add_role_id(role_id) do
    :ordsets.add_element(role_id, role_ids())
    |> set_role_ids()
  end

  defp sync(
         ~M{%M room_id, owner_id,status,member_num, map_id, members,create_time,room_name} = state
       ) do
    room =
      ~M{%Pbm.Room.Room  room_id,owner_id,status,map_id,members,member_num,create_time,room_name}

    ~M{%Pbm.Room.Update2C room} |> broad_cast()
    state
  end

  defp del_role_id(role_id) do
    :ordsets.del_element(role_id, role_ids())
    |> set_role_ids()
  end

  def broad_cast(state, msg) do
    Logger.debug("broad cast #{inspect(msg)}")
    broad_cast(msg)
    state |> ok()
  end

  defp broad_cast(msg) do
    role_ids()
    |> Enum.each(&Role.Misc.send_to(msg, &1))
  end

  defp ok(state), do: {:ok, state}

  defp check_before_start(members) do
    members
    |> Enum.filter(&(elem(&1, 0) < 10))
    |> Enum.group_by(&(elem(&1, 0) <= 5))
    |> Map.values()
    |> Enum.all?(&(length(&1) > 1))
  end
end
