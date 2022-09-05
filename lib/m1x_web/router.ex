defmodule M1xWeb.Router do
  use M1xWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {M1xWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", M1xWeb do
    pipe_through :browser
    live "/", GameDashboard
    # get "/", PageController, :index
    get "/get_pbclass", PageController, :get_pbclass
    get "/get_log", PageController, :get_log
    live "/roles", RolesLive
    live "/matchingpool", Matchingpool
    live "/modal", MailLive, :modal
    live "/teams", TeamsLive
  end

  # Other scopes may use custom stacks.
  # scope "/api", M1xWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test, :prod] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/dashboard",
        metrics: M1xWeb.Telemetry,
        additional_pages: [
          flame_on: FlameOn.DashboardPage
        ]
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
