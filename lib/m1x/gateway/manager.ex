defmodule Gateway.Manager do
  use GenServer
  use Common
  @init_delay 1000
  @loopinterval 5000

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  @impl true
  def init(_init_arg) do
    Memento.start()
    Process.send_after(self(), :loop, @init_delay)
    {:ok, %{}}
  end

  @impl true
  def handle_info(:loop, state) do
    with [_ | _] = db_list <- Dba.Manager.call(:get_mnesia_nodes) do
      Memento.add_nodes(db_list)
    else
      _ ->
        :skip
    end

    Process.send_after(self(), :loop, @loopinterval)
    {:noreply, state}
  end
end
