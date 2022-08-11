defmodule Team.Matcher.Pool do
  defstruct id: 0,
            type: 0,
            sub_type: 0,
            range_id: 0,
            elo_range: {1000, 1100},
            team_list: [],
            search_pool_ids: []

  use Common
  alias Discord.SortedSet
  alias Team.Matcher.Pool
  alias Team.Matcher.Group
  alias Team.Matcher.Team, as: T

  @type_single 0
  @type_team 1
  @type_mix 2

  @sub_type_accurate 0
  @sub_type_fuzzy_1 1
  @sub_type_fuzzy_2 2

  def new(~M{id,type,sub_type,elo_range}) do
    ~M{%Team.Matcher.Pool id, type,sub_type,elo_range}
  end

  def get_team_list(id) do
    with ~M{team_list} <- get(id) do
      team_list
    else
      _ ->
        []
    end
  end

  def scan(~M{%Pool type,team_list,search_pool_ids} = state) do
    search_pool_ids
    |> Enum.map(&get_team_list(&1))
    |> Enum.concat()
    |> SortedSet.from_enumerable()
    |> SortedSet.to_list()
    |> do_scan(type)
    |> check_start()
  end

  def set(~M{%Pool id} = state) do
    Process.put({__MODULE__, id}, state)
  end

  def get(id) do
    Process.get({__MODULE__, id})
  end

  def add_team(~M{%Pool id,team_list} = state, ~M{match_time} = team_info) do
    team_list = [{match_time, id, team_info} | team_list]
    ~M{state| team_list}
  end

  def do_scan(search_list, type, groups \\ [])

  def do_scan([], _type, groups) do
    groups
  end

  def do_scan([{_match_time, _id, team_info} | search_list], type, groups) do
    groups = do_join_group(team_info, type, groups, [])
    do_scan(search_list, type, groups)
  end

  defp do_join_group(team_info, type, [], acc) do
    group = Group.new(type, team_info)
    [group | acc] |> :lists.reverse()
  end

  defp do_join_group(team_info, type, [group | groups], acc) do
    with {:ok, group} <- Group.join(group, team_info) do
      [group | acc]
      |> Enum.reverse()
      |> Enum.concat(groups)
    else
      {:error, _} ->
        do_join_group(team_info, type, groups, [group | acc])
    end
  end

  defp check_start(groups) do
    groups
    |> Enum.each(&Group.check_start(&1))
  end
end
