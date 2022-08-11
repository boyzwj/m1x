defmodule Team.Matcher.Team do
  defstruct team_id: 0, member_num: 0, avg_elo: 0, match_time: 0, pool_id: 0, status: 0
  use Common
  alias Team.Matcher.Team, as: T

  @status_waiting 0

  @status_matched 1

  def new(~M{team_id,member_num,avg_elo,match_time}) do
    status = @status_waiting
    ~M{%__MODULE__ team_id, member_num,avg_elo, match_time,status}
  end

  def get(team_id) do
    Process.get({__MODULE__, team_id})
  end

  def set(~M{%T team_id} = team) do
    Process.put({__MODULE__, team_id}, team)
  end

  def set_match(state) do
    status = @status_matched
    ~M{state| status}
  end

  def delete(team_id) do
    Process.delete({__MODULE__, team_id})
  end
end
