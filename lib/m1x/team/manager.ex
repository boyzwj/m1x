defmodule Team.Manager do
  use GenServer
  use Common

  @loop_interval 1000
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_args) do
    Process.send_after(self(), :secondloop, @loop_interval)
    :pg.join(__MODULE__, self())
    {:ok, %{now: Util.unixtime()}}
  end

  @impl true
  def handle_call(msg, _from, state) do
    Logger.warn("receive unhandle call #{inspect(msg)}")
    {:reply, :ok, state}
  end

  @impl true
  def handle_cast(msg, state) do
    Logger.warn("unhandle cast : #{inspect(msg)}")
    {:noreply, state}
  end

  @impl true
  def handle_info(:secondloop, state) do
    Process.send_after(self(), :secondloop, @loop_interval)
    now = Util.unixtime()
    state = ~M{state| now} |> secondloop()
    {:noreply, state}
  end

  def handle_info(msg, %Dc{} = state) do
    Logger.warn("unhandle info : #{msg}")
    {:noreply, state}
  end

  @impl true
  def code_change(_old_vsn, state, _extra) do
    {:ok, state}
  end

  defp secondloop(state) do
    state
  end
end
