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

  @doc """
  队伍是否已满
  true | false
  """
  def is_full(~M{%Group side1_num, side2_num}) do
    side1_num >= @side_max && side2_num >= @side_max
  end

  @doc """
  加入队伍到分组
  {:error, :not_enough_position | :full} | {:ok, state}
  """
  def join(state, team) do
    if is_full(state) do
      {:error, :full}
    else
      do_join(state, team)
    end
  end

  defp do_join(
         ~M{%Group type,side1,side2,side1_num ,side2_num} = state,
         ~M{num} = team_info
       )
       when type == @type_single do
    cond do
      num + side1_num <= @side_max ->
        side1 = [team_info | side1]
        side1_num = side1_num + num
        {:ok, ~M{state| side1,side1_num}}

      num + side2_num <= @side_max ->
        side2 = [team_info | side2]
        side2_num = side2_num + num
        {:ok, ~M{state| side2,side2_num}}

      true ->
        {:error, :not_enough_position}
    end
  end

  def check_start(~M{%Group } = state) do
    if is_full(state) do
      start(state)
    else
      fill_single(state)
    end
  end

  def fill_single(~M{%Group type} = state) when type == @type_single do
    state
  end

  def fill_single(~M{%Group type} = state) do
    state
  end

  def start(~M{%Group side1, side2} = state) do
    state
  end
end
