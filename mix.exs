defmodule M1x.MixProject do
  use Mix.Project

  def project do
    [
      app: :m1x,
      version: "0.1.0",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      # compilers: [:gettext] ++ Mix.compilers(),
      compilers: Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {M1x.Application, []},
      extra_applications: [:logger, :sasl, :ssl, :runtime_tools, :os_mon]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.6.11"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.6"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 3.0"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.17.5"},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.6"},
      {:flame_on, "~> 0.5.0"},
      {:esbuild, "~> 0.4", runtime: Mix.env() == :dev},
      {:swoosh, "~> 1.3"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.18"},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.5"},
      {:ecto_sqlite3, "~> 0.7.7"},
      {:benchee, "~> 1.1", only: :dev},
      {:exsync, "~> 0.2.4", only: :dev},
      {:limited_queue, "~> 0.1.0"},
      {:uuid, "~> 1.1"},
      {:shorter_maps, "~> 2.2"},
      {:pipe_to, "~> 0.2.1"},
      {:sorted_set_nif, "~> 1.2.0"},
      {:logger_file_backend, "~> 0.0.13"},
      {:worker_pool, "~> 6.0"},
      {:protox, "~> 1.6"},
      {:horde, "~> 0.8.7"},
      {:libcluster, "~> 3.3"},
      {:ranch, "~> 2.1", override: true},
      {:redix, "~> 1.1"},
      {:castore, ">= 0.0.0"},
      {:poison, "~> 5.0"},
      {:lz4, "~> 0.2.4", hex: :lz4_erl},
      {:fastglobal, "~> 1.0"},
      {:manifold, "~> 1.4"},
      {:earmark, "~> 1.4"},
      {:memoize, "~> 1.4"},
      {:pockets, "~> 1.2"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "cmd --cd assets npm install"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.deploy": [
        "cmd --cd assets npm run deploy",
        "esbuild default --minify",
        "phx.digest"
      ]
    ]
  end
end
