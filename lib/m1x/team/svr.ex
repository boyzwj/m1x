defmodule Team.Svr do
  use GenServer
  use Common

  def change_mode(team_id, args) do
    {func, _} = __ENV__.function
    call(team_id, {func, args})
  end

  def exit_team(team_id, args) do
    {func, _} = __ENV__.function
    call(team_id, {func, args})
  end

  def begin_match(team_id, args) do
    {func, _} = __ENV__.function
    call(team_id, {func, args})
  end

  def name(team_id) do
    :"Team_#{team_id}"
  end

  def child_spec([team_id | _] = args) do
    %{
      id: "Team_#{team_id}",
      start: {__MODULE__, :start_link, [args]},
      shutdown: 10_000,
      restart: :transient
    }
  end

  def pid(team_id) do
    :global.whereis_name(name(team_id))
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

  def via(team_id) do
    {:global, name(team_id)}
    # {:via, Horde.Registry, {Matrix.RoleRegistry, role_id}}
  end

  def start_link([team_id | _] = args) do
    GenServer.start_link(__MODULE__, args, name: via(team_id))
  end

  @impl true
  def init([team_id, role_id, mode]) do
    state = Team.init([team_id, role_id, mode])
    {:ok, state}
  end

  @impl true
  def handle_call({func, args}, _From, state) do
    try do
      {reply, state} = apply(Team, func, [state, args])
      {:reply, reply, state}
    catch
      error ->
        {:reply, {:error, error}, state}
    end
  end

  @impl true
  def terminate(_reason, ~M{team_id} = _state) do
    Team.Manager.end_team(team_id)
    :ok
  end
end
