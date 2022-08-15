defmodule Rank.Sup do
  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      {Rank.GlobalManager, [{Rank.Test, []}]},
      {Rank.LocalManager, [{Rank.Test2, []}]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
