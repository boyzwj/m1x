defmodule Team.Sup do
  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true

  def init(_opts) do
    [
      {Team.Manager, []},
      {DynamicSupervisor,
       [
         name: DynamicTeam.Sup,
         shutdown: 1000,
         strategy: :one_for_one
       ]}
    ]
    |> Supervisor.init(strategy: :one_for_one)
  end
end
