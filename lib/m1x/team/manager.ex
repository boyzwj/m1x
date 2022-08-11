defmodule Team.Manager do
  defstruct now: nil
  use GenServer
  use Common
  @loop_interval 1000

  @id_start 1001

  def create_team(args) do
    {func, _} = __ENV__.function
    GenServer.call(__MODULE__, {func, args})
  end

  def end_team(args) do
    {func, _} = __ENV__.function
    GenServer.cast(__MODULE__, {func, args})
  end

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_args) do
    Process.send_after(self(), :secondloop, @loop_interval)
    queue = LimitedQueue.new(10_000)
    now = Util.unixtime()
    id_start = @id_start
    Process.put({__MODULE__, :team_id_pool}, {id_start, queue})
    {:ok, %Team.Manager{now: now}}
  end

  @impl true

  def handle_call({func, arg}, _from, state) do
    try do
      {reply, state} = apply(__MODULE__, func, [state, arg])
      {:reply, reply, state}
    catch
      error ->
        {:reply, error, state}
    end
  end

  def handle_call(msg, _from, state) do
    Logger.warn("receive unhandle call #{inspect(msg)}")
    {:reply, :ok, state}
  end

  @impl true
  def handle_cast({func, arg}, state) do
    try do
      {:ok, state} = apply(__MODULE__, func, [state, arg])
      {:noreply, state}
    catch
      error ->
        Logger.error("handle cast error : #{inspect(error)}")
        {:noreply, state}
    end
  end

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

  def handle_info(msg, state) do
    Logger.warn("unhandle info : #{msg}")
    {:noreply, state}
  end

  @impl true
  def code_change(_old_vsn, state, _extra) do
    {:ok, state}
  end

  ## ====================callback ===================

  def create_team(~M{%Team.Manager } = state, args) do
    {:ok, team_id} = make_team_id()
    args = [team_id | args]

    with {:ok, _pid} <- DynamicSupervisor.start_child(DynamicTeam.Sup, {Team.Svr, args}) do
      {{:ok, team_id}, state}
    else
      _ ->
        recycle_team_id(team_id)
        throw("房间创建失败")
    end
  end

  def end_team(state, team_id) do
    recycle_team_id(state, team_id)
  end

  def recycle_team_id(state, team_id) do
    recycle_team_id(team_id)
    state |> ok()
  end

  defp secondloop(state) do
    state
  end

  defp make_team_id() do
    {id_start, pool} = Process.get({__MODULE__, :team_id_pool})

    with {:ok, pool, room_id} <- LimitedQueue.pop(pool) do
      Process.put({__MODULE__, :team_id_pool}, {id_start, pool})
      Logger.debug("create team_id #{room_id}")
      {:ok, room_id}
    else
      _ ->
        room_id = id_start
        Process.put({__MODULE__, :team_id_pool}, {id_start + 1, pool})
        {:ok, room_id}
    end
  end

  defp recycle_team_id(room_id) do
    {id_start, pool} = Process.get({__MODULE__, :team_id_pool})
    pool = LimitedQueue.push(pool, room_id)
    Process.put({__MODULE__, :team_id_pool}, {id_start, pool})
  end

  defp ok(state), do: {:ok, state}
end
