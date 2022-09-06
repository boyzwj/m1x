defmodule Dba.Mnesia.Svr do
  use GenServer
  use Common

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_args) do
    state = %{}
    # :mnesia.start()

    {:ok, state}
  end

  @impl true
  def handle_info(msg, state) do
    Logger.warn("unhandle info : #{msg}")
    {:noreply, state}
  end

  @impl true
  def code_change(_old_vsn, state, _extra) do
    {:ok, state}
  end
end
