defmodule Dsa do
  use Common
  @port_range [30_001, 40_000]

  defstruct id: nil,
            dc_port: nil,
            dc_host: nil,
            dsa_port: nil,
            ds_socket: nil,
            dc_socket: nil,
            resources: nil,
            workers: %{},
            now: nil,
            status: nil,
            recv_buffer: <<>>

  @status_init 0
  @status_online 1
  @status_offline 2

  def init() do
    [min, max] = @port_range

    host = Systemip.private_ipv4() |> Tuple.to_list() |> Enum.join(".")

    resources =
      :lists.seq(min, max, 2)
      |> Enum.reduce(LimitedQueue.new(20_000), fn port, acc ->
        LimitedQueue.push(acc, {host, port})
      end)

    opts = [inet_backend: :inet, active: true] ++ [:binary]

    dsa_port = String.to_integer(System.get_env("DSA_PORT") || "20081")

    {:ok, ds_socket} = :gen_udp.open(dsa_port, opts)

    dc_host = Application.get_env(:m1x, :dc_host, '127.0.0.1')
    dc_port = Application.get_env(:m1x, :dc_port, 20001)

    %Dsa{
      id: Node.Misc.block_id(),
      dsa_port: dsa_port,
      ds_socket: ds_socket,
      resources: resources,
      now: Util.unixtime(),
      dc_host: dc_host,
      dc_port: dc_port,
      status: @status_init
    }
  end

  def secondloop(~M{%Dsa id,status,dc_host,dc_port} = state) when status == @status_init do
    with {:ok, dc_socket} <- :gen_tcp.connect(dc_host, dc_port, [:binary, active: true]) do
      Logger.info("connected to dsa center")
      status = @status_online
      ~M{state| status,dc_socket}
    else
      err ->
        Logger.info("dsa #{id} connect error #{inspect(err)}")
        state
    end
  end

  def secondloop(~M{%Dsa status,id,resources} = state) when status == @status_online do
    resources_left = LimitedQueue.size(resources)

    state
    |> send2dc(%Dc.HeartBeat2S{id: id, resources_left: resources_left})
  end

  def secondloop(~M{%Dsa status} = state) when status == @status_offline do
    status = @status_init
    ~M{state| status}
  end

  def tcp_closed(state, _socket) do
    status = @status_offline
    ~M{state|status}
  end

  def dc_msg(
        ~M{%Dsa workers,dsa_port,ds_socket} = state,
        ~M{%Dc.StartGame2C battle_id,room_id,map_id,members,infos}
      ) do
    with {:ok, state, {host, out_port}} <- get_resource(state),
         args = [battle_id, ds_socket, room_id, map_id, members, infos, host, out_port, dsa_port],
         {:ok, worker_pid} <- DynamicSupervisor.start_child(Dsa.Worker.Sup, {Dsa.Worker, args}) do
      now = Util.unixtime()
      workers = workers |> Map.put(battle_id, ~M{worker_pid, room_id, now,host, out_port})
      ~M{state| workers}
    else
      _ ->
        Logger.warning("Dsa has no resource ...")
        send2dc(state, %Dc.StartBattleFail2S{room_id: room_id})
        state
    end
  end

  def dc_msg(~M{%Dsa workers} = state, ~M{%Dc.DsMsg2C battle_id,data}) do
    with ~M{worker_pid} <- workers |> Map.get(battle_id) do
      GenServer.cast(worker_pid, {:dc2ds, PB.decode!(data)})
      state
    else
      _ ->
        Logger.warning("Dsa can't find worker with battle_id: #{battle_id}")
        state
    end
  end

  def dc_msg(state, msg) do
    Logger.warning("receive dc msg #{inspect(msg)}")
    state
  end

  def send2dc(~M{%Dsa dc_socket} = state, msg) do
    data = Dc.Pb.encode!(msg)
    len = IO.iodata_length(data)
    :ok = :gen_tcp.send(dc_socket, [<<len::16-little>> | data])
    state
  end

  def end_game(~M{%Dsa workers} = state, [battle_id, room_id]) do
    Logger.debug("game end battle_id : #{battle_id}")
    send2dc(state, %Dc.BattleEnd2S{room_id: room_id})

    with {~M{host, port}, workers} <- Map.pop(workers, battle_id) do
      state = recycle_resource(state, {host, port})
      {:ok, ~M{state|workers}}
    else
      _ ->
        {:ok, state}
    end
  end

  def handle(~M{%Dsa workers } = state, ~M{battle_id} = msg) do
    with ~M{worker_pid} <- workers[battle_id] do
      GenServer.cast(worker_pid, {:msg, msg})
    else
      _ ->
        nil
        # Logger.warn("receive unexpected msg : #{inspect(msg)}")
    end

    state
  end

  def handle(state, msg) do
    Logger.warn("unhandle dsa msg #{inspect(msg)}")
    state
  end

  defp get_resource(~M{%Dsa resources} = state) do
    with {:ok, resources, res} <- LimitedQueue.pop(resources) do
      {:ok, ~M{state| resources}, res}
    else
      _ ->
        {:error, :resource_used_out}
    end
  end

  defp recycle_resource(~M{%Dsa resources} = state, res) do
    resources = LimitedQueue.push(resources, res)
    ~M{state| resources}
  end
end
