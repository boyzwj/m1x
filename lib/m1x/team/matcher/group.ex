defmodule Team.Matcher.Group do
  defstruct type: 0, side1: [], side1_num: 0, side2: [], side2_num: 0
  use Common
  alias Team.Matcher.Group
  @type_single 0
  @type_team 1
  @type_mix 2
  @side_max 5

  def new(type, ~M{team_id,elo,num}) do
    %__MODULE__{type: type, side1: [{team_id, num, elo}], side1_num: num}
  end

  def is_full(~M{%Group side1_num, side2_num}) do
    side1_num >= @side_max && side2_num >= @side_max
  end

  def join(state, team) do
    if is_full(state) do
      {:error, :full}
    else
      do_join(state, team)
    end
  end

  def check_start(state) do
    state
  end

  defp do_join(~M{%Group type,side1,side2,side1_num ,side2_num} = state, ~M{team_id,avg_elo,num})
       when type == @type_single do
    cond do
      num + side1_num <= @side_max ->
        side1 = [~M{team_id,avg_elo,num} | side1]
        side1_num = side1_num + num
        {:ok, ~M{state| side1,side1_num}}

      num + side2_num <= @side_max ->
        side2 = [~M{team_id,avg_elo,num} | side2]
        side2_num = side2_num + num
        {:ok, ~M{state| side2,side2_num}}

      true ->
        {:error, :not_enough_position}
    end
  end
end
