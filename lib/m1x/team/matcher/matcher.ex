defmodule Team.Matcher do
  defstruct team_ids: nil, pool_ids: nil, now: 0
  use Common
  alias Team.Matcher
  alias Team.Matcher.Pool
  alias Team.Matcher.Team, as: MTeam
  @max_team_member_count 5
  @loop_interval 1000

  @type_single 1
  @type_team 2
  @type_mix 3
  @type_warm 4

  def init(_mode_args) do
    Process.send_after(self(), :loop, @loop_interval)
    pool_ids = init_pool()
    %Team.Matcher{pool_ids: pool_ids, now: Util.unixtime(), team_ids: MapSet.new()}
  end

  def init_pool() do
    for base_id <- Data.MatchPool.ids(),
        type <- [@type_single, @type_team, @type_mix, @type_warm] do
      Pool.new(~M{base_id, type})
      |> Pool.set()
      |> Map.get(:id)
    end
  end

  def join(~M{%__MODULE__  now, team_ids} = state, [
        team_id,
        member_num,
        avg_elo,
        warm
      ])
      when member_num >= 1 and member_num <= @max_team_member_count do
    pool_type =
      cond do
        warm == true -> @type_warm
        member_num == 1 -> @type_single
        true -> @type_team
      end

    base_pool_id = Pool.get_base_id_by_elo(avg_elo)
    pool_id = {pool_type, base_pool_id}
    team_info = MTeam.new(~M{team_id,member_num,avg_elo,base_pool_id,pool_id,match_time: now})
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

  defp loop_team(~M{%Matcher team_ids,now} = state) do
    for team_id <- team_ids do
      MTeam.get(team_id)
      |> MTeam.loop(now)
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

  def test1() do
    Team.Matcher.Svr.join(1001, [1, 2, 1200, false])
    Team.Matcher.Svr.join(1001, [2, 3, 1300, false])
    Team.Matcher.Svr.join(1001, [3, 2, 1300, false])
    Team.Matcher.Svr.join(1001, [4, 3, 1200, false])
  end

  def test2() do
    Team.Matcher.Svr.join(1002, [101, 1, 1600, true])
    Team.Matcher.Svr.join(1002, [102, 2, 1650, true])
    Team.Matcher.Svr.join(1002, [103, 1, 1650, true])
    Team.Matcher.Svr.join(1002, [104, 1, 1600, true])
  end
end
