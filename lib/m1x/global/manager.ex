defmodule Global.Manager do
  use GenServer
  use Common

  def clear_cache(mod, fun, args) do
    :pg.get_members(__MODULE__)
    |> Enum.each(&GenServer.cast(&1, {:clear_cache, mod, fun, args}))
  end

  def call(args) do
    GenServer.call(__MODULE__, args)
  end

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_args) do
    Process.send_after(self(), :start_global, 100)
    :pg.join(__MODULE__, self())
    {:ok, %{}}
  end

  @impl true
  def handle_call(args, _from, state) do
    Logger.warn("receive unhandle call : #{inspect(args)}")
    reply = :ok
    {:reply, reply, state}
  end

  @impl true
  def handle_info(:start_global, state) do
    start_global()
    {:noreply, state}
  end

  @impl true
  def handle_cast({:clear_cache, mod, fun, args}, state) do
    Memoize.invalidate(mod, fun, args)
    {:noreply, state}
  end

  defp start_global() do
    Logger.info("start global dba manaer")

    Horde.DynamicSupervisor.start_child(
      Matrix.DistributedSupervisor,
      {Dba.Manager, []}
    )

    Logger.info("start global redis")

    for worker_id <- 1..Application.get_env(:m1x, :db_worker_num, 8) do
      Horde.DynamicSupervisor.start_child(
        Matrix.DistributedSupervisor,
        {Redis, worker_id}
      )
    end

    Logger.info("start mail global")
    Horde.DynamicSupervisor.start_child(Matrix.MailSupervisor, {Mail.Global, []})

    Logger.info("start global rank")
    Horde.DynamicSupervisor.start_child(Matrix.RankSupervisor, {Rank.Test, []})

    Logger.info("start global matcher")

    for mode <- Data.GameModeManage.ids() do
      Horde.DynamicSupervisor.start_child(
        Matrix.DistributedSupervisor,
        {Matcher.Svr, mode}
      )
    end
  end
end
