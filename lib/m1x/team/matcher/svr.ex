defmodule Team.Matcher.Svr do
  use GenServer
  use Common

  def join(mode, args) do
    call(mode, {:join, args})
  end

  def ready_match(mode, args) do
    call(mode, {:ready_match, args})
  end

  def get_pool_infos(mode, args) do
    call(mode, {:get_pool_infos, args})
  end

  def child_spec(mode) do
    %{
      id: "#{__MODULE__}_#{mode}",
      start: {__MODULE__, :start_link, [mode]},
      shutdown: 10_000,
      restart: :transient,
      type: :worker
    }
  end

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(mode) do
    GenServer.start_link(__MODULE__, [mode], name: via(mode))
  end

  @impl true
  def handle_call({func, args}, _from, state) do
    {reply, state} = apply(Team.Matcher, func, [state, args])
    {:reply, reply, state}
  end

  @impl true
  def handle_info(:loop, state) do
    state = Team.Matcher.loop(state)
    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.error("unexpected info #{inspect(msg)}")
    {:noreply, state}
  end

  @impl true
  def handle_cast(msg, state) do
    Logger.error("unexpected cast #{inspect(msg)}")
    {:noreply, state}
  end

  defp via(mode) do
    {:via, Horde.Registry, {Matrix.DBRegistry, mode}}
  end

  @impl true
  def init(args) do
    state = Team.Matcher.init(args)
    {:ok, state}
  end

  def call(mode, args) do
    via(mode) |> GenServer.call(args)
  end

  def cast(mode, args) do
    via(mode) |> GenServer.cast(args)
  end
end
