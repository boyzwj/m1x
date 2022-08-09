defmodule Rank.GlobalManager do
  use GenServer
  use Common

  def start_worker(rank_name, args) do
    GenServer.call(__MODULE__, {:start_worker, [{rank_name, args}]})
  end

  def start_link(opt) do
    GenServer.start_link(__MODULE__, opt, name: __MODULE__)
  end

  @impl true
  def init(args) do
    Logger.debug("Rank global manager start")
    interval = Util.rand(1, 100)
    Process.send_after(self(), {:start_worker, args}, interval)
    {:ok, {}}
  end

  @impl true
  def handle_info({:start_worker, list}, state) do
    for {rank_name, args} <- list do
      Horde.DynamicSupervisor.start_child(Matrix.RankSupervisor, {rank_name, args})
    end

    {:noreply, state}
  end
end
