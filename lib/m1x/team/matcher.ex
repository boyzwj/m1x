defmodule Team.Matcher do
  defstruct pool: %{}
  use GenServer
  use Common

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

  defp via(mode) do
    {:via, Horde.Registry, {Matrix.DBRegistry, mode}}
  end

  @impl true
  def init(_args) do
    {:ok, %Team.Matcher{}}
  end

  def call(mode, args) do
    via(mode) |> GenServer.call(args)
  end

  def cast(mode, args) do
    via(mode) |> GenServer.cast(args)
  end
end
