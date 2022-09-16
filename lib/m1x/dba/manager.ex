defmodule Dba.Manager do
  use GenServer
  use Common
  defstruct db_nodes: []

  def call(args) do
    GenServer.call(via(), args)
  end

  def cast(args) do
    GenServer.cast(via(), args)
  end

  def child_spec() do
    # worker_id = Keyword.fetch!(opts, :worker_id)

    %{
      id: "#{__MODULE__}",
      start: {__MODULE__, :start_link, []},
      shutdown: 10_000,
      restart: :transient,
      type: :worker
    }
  end

  def start_link(args) do
    # Logger.debug("start redis #{worker_id}")
    GenServer.start_link(__MODULE__, args, name: via())
  end

  @impl true
  def init(_args) do
    Process.flag(:trap_exit, true)
    # interval = Util.rand(1, 500)
    # Process.send_after(self(), :connect_all, interval)
    {:ok, %__MODULE__{}}
  end

  @impl true

  def handle_call(:get_mnesia_nodes, _from, %__MODULE__{db_nodes: db_nodes} = state) do
    {:reply, db_nodes, state}
  end

  def handle_call({:regist_mnesia, node}, _from, %__MODULE__{db_nodes: db_nodes} = state) do
    db_nodes = [node | db_nodes]
    {:reply, :ok, %{state | db_nodes: db_nodes}}
  end

  def handle_call(args, _from, state) do
    Logger.warn("receive unhandle call : #{inspect(args)}")
    reply = :error
    {:reply, reply, state}
  end

  @impl true
  def terminate(reason, _state) do
    Logger.info("#{__MODULE__} terminate,reason: #{inspect(reason)}")
    :ok
  end

  defp via() do
    {:via, Horde.Registry, {Matrix.GlobalRegistry, __MODULE__}}
  end
end
