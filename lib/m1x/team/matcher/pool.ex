defmodule Team.Matcher.Pool do
  defstruct id: 0,
            base_id: 0,
            type: 0,
            range_id: 0,
            team_list: nil

  use Common
  alias Discord.SortedSet
  alias Team.Matcher.Pool
  alias Team.Matcher.Group
  alias Team.Matcher.Team, as: MTeam

  @type_single 1
  @type_team 2
  @type_mix 3
  @type_warm 4

  def new(~M{base_id,type}) do
    id = {type, base_id}
    team_list = SortedSet.new()
    ~M{%Pool id, base_id,type,team_list}
  end

  def get_base_id_by_elo(elo_value) do
    Data.MatchScore.query(&(elo_value <= &1.elo_max && elo_value >= &1.elo_min))
    |> List.first()
    |> Map.get(:elo_pot)
  end

  def get_team_list(id) do
    with ~M{team_list} <- get(id) do
      team_list |> SortedSet.to_list()
    else
      _ ->
        []
    end
  end

  def get_waiting_team_list(id) do
    with ~M{team_list} <- get(id) do
      team_list
      |> SortedSet.to_list()
      |> Enum.map(fn {_, _, team_id} ->
        MTeam.get(team_id)
      end)
      |> Enum.filter(&(&1.status == 0))
    else
      _ ->
        []
    end
  end

  def scan(~M{%Pool id,team_list} = state) do
    team_list
    |> SortedSet.to_list()
    |> do_scan(id)
    |> join_robot()
    |> check_start()

    state
  end

  def set(~M{%Pool id} = state) do
    Process.put({__MODULE__, id}, state)
    state
  end

  def get(id) do
    Process.get({__MODULE__, id})
  end

  def add_team(~M{%Pool id,team_list} = state, ~M{match_time,team_id}) do
    team_list = SortedSet.add(team_list, {match_time, id, team_id})
    ~M{state| team_list}
  end

  def remove_team(~M{%Pool team_list} = state, team_id) do
    team_list =
      team_list
      |> SortedSet.to_list()
      |> Enum.filter(fn {_, _, t} -> t != team_id end)
      |> SortedSet.from_enumerable()

    ~M{state| team_list}
  end

  def do_scan(search_list, id, groups \\ [])

  def do_scan([], _id, groups) do
    groups
  end

  def do_scan([{_match_time, _id, team_id} | search_list], id, groups) do
    team_info = MTeam.get(team_id)

    if MTeam.matched?(team_info) do
      do_scan(search_list, id, groups)
    else
      groups = do_join_group(team_info, id, groups, [])
      do_scan(search_list, id, groups)
    end
  end

  defp do_join_group(team_info, id, [], acc) do
    group = Group.new(id, team_info)
    [group | acc] |> :lists.reverse()
  end

  defp do_join_group(team_info, type, [group | groups], acc) do
    with {:ok, group} <- Group.join(group, team_info) do
      [group | acc] |> Enum.reverse() |> Enum.concat(groups)
    else
      {:error, _} ->
        do_join_group(team_info, type, groups, [group | acc])
    end
  end

  defp check_start(groups) do
    groups |> Enum.each(&Group.check_start(&1))
  end

  defp join_robot(group) do
    group
  end
end
