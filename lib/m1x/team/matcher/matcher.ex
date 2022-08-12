defmodule Team.Matcher do
  defstruct teams: nil, match_queue: nil, pools: nil, now: 0
  use Common
  alias Discord.SortedSet
  alias Team.Matcher.Pool
  @max_team_member_count 5
  @loop_interval 1000

  def init(_mode_args) do
    pools = for num <- 1..@max_team_member_count, into: %{}, do: {num, %{}}
    Process.send_after(self(), :loop, @loop_interval)
    match_queue = SortedSet.new(5000)
    %Team.Matcher{pools: pools, now: Util.unixtime(), match_queue: match_queue, teams: %{}}
  end

  def join(~M{%__MODULE__ pools, match_queue, now, teams} = state, [
        team_id,
        num,
        avg_elo
      ])
      when num >= 1 and num <= @max_team_member_count do
    pool = pools[num]
    pool = Map.put(pool, team_id, {avg_elo, now})
    pools = Map.put(pools, num, pool)
    SortedSet.add(match_queue, {now, team_id})
    teams = Map.put(teams, team_id, {num, avg_elo, now})
    ~M{state | pools,teams} |> reply(:ok)
  end

  def cancel_match(~M{%__MODULE__ pools, match_queue,teams} = state, [team_id]) do
    with {_num, _elo, timestamp} <- teams[team_id] do
      SortedSet.remove(match_queue, {timestamp, team_id})
    else
      _ ->
        state |> reply(:ok)
    end
  end

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
