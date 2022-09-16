defmodule M1x.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        %{id: :pg, start: {:pg, :start_link, []}},
        # Start the Telemetry supervisor
        M1xWeb.Telemetry,
        # Start the PubSub system
        {Phoenix.PubSub, name: M1x.PubSub},
        # Start the Endpoint (http/https)
        M1xWeb.Endpoint
        # Start a worker by calling: M1x.Worker.start_link(arg)
        # {M1x.Worker, arg}
      ] ++ NodeConfig.services()

    PB.modules() |> Enum.each(&Code.ensure_loaded/1)
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: M1x.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    M1xWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
