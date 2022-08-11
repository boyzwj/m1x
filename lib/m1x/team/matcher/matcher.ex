defmodule Team.Matcher do
  defstruct match_queue: nil, pools: nil, now: 0
  use Common
  alias Discord.SortedSet
  @max_team_member_count 5
  @loop_interval 1000

  def init() do
    pools = for num <- 1..@max_team_member_count, into: %{}, do: {num, %{}}
    Process.send_after(self(), :loop, @loop_interval)
    match_queue = SortedSet.new(5000)
    %Team.Matcher{pools: pools, now: Util.unixtime(), match_queue: match_queue}
  end

  def join(%__MODULE__{pools: pools, match_queue: match_queue, now: now} = state, [
        team_id,
        num,
        avg_elo
      ])
      when num >= 1 and num <= @max_team_member_count do
    pool = pools[num]
    pool = Map.put(pool, team_id, {avg_elo, now})
    pools = Map.put(pools, num, pool)
    SortedSet.add(match_queue, {now, team_id})
    ~M{state |pools} |> reply(:ok)
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
