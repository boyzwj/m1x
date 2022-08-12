defmodule Team.Matcher do
  defstruct teams: nil, pool_ids: nil, now: 0
  use Common
  alias Discord.SortedSet
  alias Team.Matcher.Pool
  @max_team_member_count 5
  @loop_interval 1000

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
    %Team.Matcher{pool_ids: pool_ids, now: Util.unixtime(), teams: %{}}
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

  # def join(~M{%__MODULE__ pool_ids, now, teams} = state, [
  #       team_id,
  #       num,
  #       avg_elo
  #     ])
  #     when num >= 1 and num <= @max_team_member_count do
  #   get_

  #   pool = pools[num]
  #   pool = Map.put(pool, team_id, {avg_elo, now})
  #   pools = Map.put(pools, num, pool)
  #   SortedSet.add(match_queue, {now, team_id})
  #   teams = Map.put(teams, team_id, {num, avg_elo, now})
  #   ~M{state | pools,teams} |> reply(:ok)
  # end

  # def cancel_match(~M{%__MODULE__ pools, match_queue,teams} = state, [team_id]) do
  #   with {_num, _elo, timestamp} <- teams[team_id] do
  #     SortedSet.remove(match_queue, {timestamp, team_id})
  #   else
  #     _ ->
  #       state |> reply(:ok)
  #   end
  # end

  def loop(state) do
    Process.send_after(self(), :loop, @loop_interval)
    now = Util.unixtime()
    ~M{state|now} |> do_match()
  end

  defp do_match(state) do
    state
  end

  defp reply(state, reply) do
    {reply, state}
  end
end
