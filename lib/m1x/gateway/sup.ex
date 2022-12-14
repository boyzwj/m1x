defmodule GateWay.ListenerSup do
  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args)
  end

  @impl true
  def init(_opts) do
    port = String.to_integer(System.get_env("PORT") || "4001")

    children = [
      {GateWay.GameListener, port: port},
      {Gateway.Manager, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
