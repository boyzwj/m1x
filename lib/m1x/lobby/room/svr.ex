defmodule Lobby.Room.Svr do
  use GenServer
  use Common

  @doc """
  加入房间
  """
  def join(room_id, args) do
    {func, _} = __ENV__.function
    call(room_id, {func, args})
  end

  @doc """
  设置房间地图
  """
  def set_map(room_id, args) do
    {func, _} = __ENV__.function
    cast(room_id, {func, args})
  end

  @doc """
  踢人
  """
  def kick(room_id, args) do
    {func, _} = __ENV__.function
    cast(room_id, {func, args})
  end

  @doc """
  换位置
  """
  def change_pos(room_id, args) do
    {func, _} = __ENV__.function
    cast(room_id, {func, args})
  end

  def change_pos_reply(room_id, args) do
    {func, _} = __ENV__.function
    cast(room_id, {func, args})
  end

  def broad_cast(room_id, args) do
    {func, _} = __ENV__.function
    cast(room_id, {func, args})
  end

  @doc """
  退出房间
  """
  def exit_room(room_id, args) do
    {func, _} = __ENV__.function
    call(room_id, {func, args})
  end

  @doc """
  开始游戏
  """
  def start_game(room_id, args) do
    {func, _} = __ENV__.function
    call(room_id, {func, args})
  end

  def pid(room_id) do
    :global.whereis_name(name(room_id))
  end

  def name(room_id) do
    :"Room_#{room_id}"
  end

  def via(room_id) do
    {:global, name(room_id)}
    # {:via, Horde.Registry, {Matrix.RoleRegistry, role_id}}
  end

  def cast(room_id, msg) when is_integer(room_id) do
    with pid when is_pid(pid) <- name(room_id) |> :global.whereis_name() do
      cast(pid, msg)
    else
      _ ->
        {:error, :room_not_exist}
    end
  end

  def cast(pid, msg) when is_pid(pid) do
    pid |> GenServer.cast(msg)
  end

  def call(room_id, msg) when is_integer(room_id) do
    with pid when is_pid(pid) <- name(room_id) |> :global.whereis_name() do
      call(pid, msg)
    else
      _ ->
        {:error, :room_not_exist}
    end
  end

  def call(pid, msg) when is_pid(pid) do
    pid |> GenServer.call(msg)
  end

  def child_spec([room_id | _] = args) do
    %{
      id: "Room_#{room_id}",
      start: {__MODULE__, :start_link, [args]},
      shutdown: 10_000,
      restart: :transient
    }
  end

  def start_link([room_id | _] = args) do
    GenServer.start_link(__MODULE__, args, name: via(room_id))
  end

  @impl true
  def init(args) do
    state = Lobby.Room.init(args)
    {:ok, state}
  end

  @impl true
  def handle_info(:secondloop, state) do
    state = Lobby.Room.secondloop(state)
    {:noreply, state}
  end

  def handle_info(:shutdown, state) do
    Logger.debug("room shut down")
    {:stop, :normal, state}
  end

  @impl true
  def handle_cast({func, args}, state) do
    try do
      {:ok, state} = :erlang.apply(Lobby.Room, func, [state, args])
      Lobby.Room.set_dirty(true)
      {:noreply, state}
    catch
      error ->
        Logger.error(
          "handle cast error Fun: #{func} args: #{inspect(args)}, error: #{inspect(error)}"
        )

        {:noreply, state}
    end
  end

  @impl true
  def handle_call({func, args}, _From, state) do
    try do
      {reply, state} = apply(Lobby.Room, func, [state, args])
      Lobby.Room.set_dirty(true)
      {:reply, reply, state}
    catch
      error ->
        {:reply, {:error, error}, state}
    end
  end

  @impl true
  def terminate(:normal, ~M{room_id} = _state) do
    :ets.delete(Room, room_id)
    Lobby.Svr.recycle_room(room_id)
    :ok
  end

  def terminate(_reason, _state) do
    :ok
  end
end
