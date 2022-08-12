defmodule Mail.Manager do
  use GenServer
  use Common

  def clear_cache(mod, fun, args) do
    :pg.get_members(__MODULE__)
    |> Enum.each(&GenServer.cast(&1, {:clear_cache, mod, fun, args}))
  end

  def start_link(opt) do
    GenServer.start_link(__MODULE__, opt, name: __MODULE__)
  end

  @impl true
  def init(args) do
    Logger.debug("Mail manager start")
    interval = Util.rand(1, 100)
    Process.send_after(self(), {:start_worker, args}, interval)
    :pg.join(__MODULE__, self())
    {:ok, {}}
  end

  @impl true
  def handle_info({:start_worker, _}, state) do
    Horde.DynamicSupervisor.start_child(Matrix.MailSupervisor, {Mail.Global, []})
    {:noreply, state}
  end

  @impl true
  def handle_cast({:clear_cache, mod, fun, args}, state) do
    Memoize.invalidate(mod, fun, args)
    {:noreply, state}
  end
end
