defmodule Dba.Mnesia.Svr do
  use GenServer
  use Common

  def dirty_write(data) when is_struct(data) do
    # tab = data.__struct__
    # key = data.id
    # worker_id = :erlang.phash2({tab, key}, @db_worker_num) + 1
    GenServer.call(__MODULE__, {:dirty_write, data})
  end

  def dirty_read(tab, key) do
    GenServer.call(__MODULE__, {:dirty_read, tab, key})
  end

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_args) do
    state = %{}
    # :mnesia.start()
    Process.send_after(self(), :register, 1000)
    {:ok, state}
  end

  @impl true

  def handle_call({:dirty_read, tab, key}, _from, state) do
    Logger.debug("do dirty read #{inspect(self())}")

    reply =
      case :mnesia.dirty_read(tab, key) do
        [t] -> Memento.Query.Data.load(t)
        [] -> nil
      end

    {:reply, reply, state}
  end

  def handle_call({:dirty_wirte, data}, _from, state) do
    reply =
      data
      |> Memento.Query.Data.dump()
      |> :mnesia.dirty_write()

    {:reply, reply, state}
  end

  @impl true

  def handle_info(:register, state) do
    db_list = []
    Dba.Mnesia.Manager.initialize(db_list)
    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.warn("unhandle info : #{msg}")
    {:noreply, state}
  end

  @impl true
  def code_change(_old_vsn, state, _extra) do
    {:ok, state}
  end
end
