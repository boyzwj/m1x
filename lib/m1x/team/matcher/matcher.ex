defmodule Team.Matcher do
  defstruct team_ids: nil, pool_ids: nil, now: 0
  use Common
  alias Team.Matcher
  alias Team.Matcher.Pool
  alias Team.Matcher.Team, as: MTeam
  alias Team.Matcher.Group
  @max_team_member_count 5
  @loop_interval 1000

  @type_single 1
  @type_team 2
  @type_mix 3
  @type_warm 4

  def init([mode | _]) do
    Logger.debug("start matcher , mode: #{mode}")
    Process.send_after(self(), :loop, @loop_interval)
    pool_ids = init_pool()
    Process.put({__MODULE__, :mode}, mode)
    %Team.Matcher{pool_ids: pool_ids, now: Util.unixtime(), team_ids: MapSet.new()}
  end

  @spec random_map_id :: integer()
  def random_map_id() do
    mode = Process.get({__MODULE__, :mode})
    random_map_by_mode(mode)
  end

  defp random_map_by_mode(mode) do
    Data.GameModeMap.query(&(&1.mode_id == mode))
    |> Enum.random()
    |> Map.get(:id)
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
        role_ids,
        avg_elo,
        warm
      ])
      when length(role_ids) >= 1 and length(role_ids) <= @max_team_member_count do
    member_num = length(role_ids)

    pool_type =
      cond do
        warm == true -> @type_warm
        member_num == 1 -> @type_single
        true -> @type_team
      end

    base_pool_id = Pool.get_base_id_by_elo(avg_elo)
    pool_id = {pool_type, base_pool_id}

    team_info =
      MTeam.new(~M{team_id,member_num,role_ids,avg_elo,base_pool_id,pool_id,match_time: now})

    Pool.get(pool_id) |> Pool.add_team(team_info) |> Pool.set()
    MTeam.set(team_info)
    team_ids = MapSet.put(team_ids, team_id)
    ~M{state | team_ids} |> reply(:ok)
  end

  def ready_match(~M{%__MODULE__ } = state, [team_id, role_id, reply]) do
    with ~M{%MTeam token} <- MTeam.get(team_id),
         ~M{%Group } = group <- Group.get(token) do
      with :ok <- Group.client_reply(group, [team_id, role_id, reply]) do
        :ok
      else
        {:error, team_id} ->
          cancel_match(state, [team_id])
      end

      state |> reply(:ok)
    else
      _ ->
        state |> reply(:ok)
    end
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

  def get_pool_infos(~M{%__MODULE__ } = state, _args) do
    pool_infos =
      for base_id <- Data.MatchPool.ids(),
          type <- [@type_single, @type_team, @type_mix, @type_warm] do
        Pool.get({type, base_id})
      end

    reply(state, pool_infos)
  end

  def get_group_infos(~M{%__MODULE__ } = state, _args) do
    group_infos =
      for token <- Group.get_waiting_list() do
        Group.get(token)
      end

    reply(state, group_infos)
  end

  def loop(state) do
    Process.send_after(self(), :loop, @loop_interval)
    now = Util.unixtime()

    ~M{state|now}
    |> loop_group()
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

  defp loop_group(state) do
    for token <- Group.get_waiting_list() do
      Group.get(token) |> Group.loop()
    end

    state
  end

  defp reply(state, reply) do
    {reply, state}
  end

  def test3() do
    Team.Matcher.Svr.join(1002, [101, [1001], 1600, false])
    Team.Matcher.Svr.join(1002, [102, [1002, 1003, 1004, 1005], 1670, false])
    Team.Matcher.Svr.join(1002, [103, [1006], 1650, false])
    Team.Matcher.Svr.join(1002, [104, [1007, 1008, 1009, 1100], 1500, false])
  end
end
