defmodule Team.Matcher.Svr do
  use GenServer
  use Common

  def join(mod, args) do
    call(mod, {:join, args})
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

  def start_link(mode) do
    Logger.debug("start Team matcher, Mode is  #{mode}")
    GenServer.start_link(__MODULE__, [], name: via(mode))
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
  def init(_args) do
    state = Team.Matcher.init()
    {:ok, state}
  end

  def call(mode, args) do
    via(mode) |> GenServer.call(args)
  end

  def cast(mode, args) do
    via(mode) |> GenServer.cast(args)
  end
end