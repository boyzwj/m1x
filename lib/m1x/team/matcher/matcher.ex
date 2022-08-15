defmodule Team.Matcher do
  defstruct team_ids: nil, pool_ids: nil, now: 0
  use Common
  alias Team.Matcher
  alias Team.Matcher.Pool
  alias Team.Matcher.Team, as: MTeam
  @max_team_member_count 5
  @loop_interval 500

  @type_single 0
  @type_team 1
  @type_mix 2
  @type_warm 3

  @sub_type_accurate 0
  @sub_type_fuzzy_1 1
  @sub_type_fuzzy_2 2

  def init(_mode_args) do
    Process.send_after(self(), :loop, @loop_interval)
    pool_ids = init_pool()
    %Team.Matcher{pool_ids: pool_ids, now: Util.unixtime(), team_ids: MapSet.new()}
  end

  def init_pool() do
    for base_id <- Data.MatchPool.ids(),
        type <- [@type_single, @type_team, @type_mix, @type_warm] do
      cond do
        type in [@type_mix, @type_warm] ->
          Pool.new(~M{base_id, type, sub_type: 0})
          |> Pool.set()
          |> Map.get(:id)
          |> (&[&1]).()

        type in [@type_single, @type_team] ->
          for sub_type <- [@sub_type_accurate, @sub_type_fuzzy_1, @sub_type_fuzzy_2] do
            Pool.new(~M{base_id, type, sub_type})
            |> Pool.set()
            |> Map.get(:id)
          end
      end
    end
    |> Enum.concat()
  end

  def join(~M{%__MODULE__  now, team_ids} = state, [
        team_id,
        member_num,
        avg_elo
      ])
      when member_num == 1 do
    pool_id =
      Pool.get_base_id_by_elo(avg_elo)
      |> Pool.make_id(@type_single, @sub_type_accurate)

    team_info = MTeam.new(~M{team_id,member_num,avg_elo,pool_id,match_time: now})
    Pool.get(pool_id) |> Pool.add_team(team_info) |> Pool.set()
    MTeam.set(team_info)
    team_ids = MapSet.put(team_ids, team_id)
    ~M{state | team_ids} |> reply(:ok)
  end

  def join(~M{%__MODULE__  now, team_ids} = state, [
        team_id,
        member_num,
        avg_elo
      ])
      when member_num < @max_team_member_count do
    pool_id =
      Pool.get_base_id_by_elo(avg_elo)
      |> Pool.make_id(@type_team, @sub_type_accurate)

    team_info = MTeam.new(~M{team_id,member_num,avg_elo,pool_id,match_time: now})
    Pool.get(pool_id) |> Pool.add_team(team_info) |> Pool.set()
    MTeam.set(team_info)
    team_ids = MapSet.put(team_ids, team_id)
    ~M{state | team_ids} |> reply(:ok)
  end

  def cancel_match(~M{%__MODULE__ team_ids} = state, [team_id]) do
    if not MapSet.member?(team_ids, team_id) do
      throw("不在匹配队列中了")
    end

    with ~M{%MTeam pool_id} <- MTeam.get(team_id) do
      Pool.get(pool_id) |> Pool.remove_team(team_id) |> Pool.set()
      MTeam.delete(team_id)
      team_ids = MapSet.delete(team_ids, team_id)
      ~M{state | team_ids} |> reply(:ok)
    else
      _ ->
        throw("队伍信息异常")
    end
  end

  def loop(state) do
    Process.send_after(self(), :loop, @loop_interval)
    now = Util.unixtime()

    ~M{state|now}
    |> loop_team()
    |> loop_pool()
  end

  defp loop_team(~M{%Matcher team_ids} = state) do
    for team_id <- team_ids do
      MTeam.get(team_id)
      |> MTeam.loop()
      |> MTeam.set()
    end

    state
  end

  defp loop_pool(~M{%Matcher pool_ids} = state) do
    for pool_id <- pool_ids do
      Pool.get(pool_id)
      |> Pool.scan()
      |> Pool.set()
    end

    state
  end

  defp reply(state, reply) do
    {reply, state}
  end
end
