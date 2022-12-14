defmodule Robot.FSM do
  use Common
  alias Robot.Worker

  @status_init 0
  @status_connected 1
  @status_online 2
  @status_offline 3
  @status_reconnecting 4

  def server_list() do
    [{'127.0.0.1', 4001}]
    # [{'192.168.15.101', 4001}]
    # [{'127.0.0.1', 4001},{'127.0.0.1', 4002}]
  end

  def loop(%Worker{id: id, status: @status_init} = state) do
    {addr, port} = Util.rand_list(server_list())

    with {:ok, socket} <- :gen_tcp.connect(addr, port, [:binary, active: true]) do
      Logger.debug("socket connected")
      status = @status_connected
      ~M{%Worker state| addr,port,socket,status} |> loop()
    else
      err ->
        Logger.debug("robot #{id} connect error #{inspect(err)}")
        state
    end
  end

  def loop(%Worker{status: @status_connected} = state) do
    Worker.send_authorize(state)
  end

  def loop(%Worker{status: @status_online} = state) do
    # requests =
    #   for role_id <- 1..10 do
    #     %Role.InfoRequest{role_id: role_id, timestamp: 0}
    #   end

    state
    |> Worker.send_ping()

    # |> Worker.send_buf(%Role.Info2S{})
    # |> Worker.send_buf(%Role.OtherInfo2S{requests: requests})
    # |> Worker.send_buf(%Chat.Chat2S{content: "这是一条聊天信息"})
    # |> Worker.send_buf(%Pbm.Room.Create2S{map_id: 10_051_068, password: ""})
    # |> Worker.send_buf(%Pbm.Room.List2S{})
    # |> Worker.send_buf(%Pbm.Room.Exit2S{})
  end

  def loop(%Worker{status: @status_offline, addr: addr, port: port} = state) do
    Logger.debug("offline , try to reconnect")

    with {:ok, socket} <- :gen_tcp.connect(addr, port, [:binary, active: true]) do
      status = @status_reconnecting
      ~M{%Worker state| socket,status} |> loop()
    else
      err ->
        Logger.debug("reconnect fail, #{inspect(err)}")
        state
    end
  end

  def loop(%Worker{status: @status_reconnecting} = state) do
    Logger.debug("socket connected, try resume session")
    Worker.send_reconnect(state)
    state
  end

  def login_ok(state) do
    status = @status_online
    ~M{%Worker state| status}
  end

  def sd(worker_id, msg) do
    Robot.Worker.via_tuple(worker_id)
    |> GenServer.cast({:handle, msg})
  end

  def h(%Worker{status: @status_online} = state, msg) do
    Worker.send_buf(state, msg)
  end
end
