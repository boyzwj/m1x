defmodule Team.Matcher.Group do
  defstruct base_id: 0, type: 0, side1: [], side1_num: 0, side2: [], side2_num: 0
  use Common
  alias Team.Matcher.Group
  alias Team.Matcher.Pool
  @type_single 1
  @type_team 2
  @type_mix 3
  @type_warm 4

  @side_max 5

  def new(pool_id, ~M{member_num} = team_info) do
    {type, base_id} = pool_id
    %__MODULE__{base_id: base_id, type: type, side1: [team_info], side1_num: member_num}
  end

  @doc """
  队伍是否已满
  true | false
  """
  def is_full(~M{%Group type,side1_num}) when type == @type_warm do
    side1_num >= @side_max
  end

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
         ~M{member_num} = team_info
       )
       when type == @type_team do
    cond do
      member_num + side1_num <= @side_max ->
        side1 = [team_info | side1]
        side1_num = side1_num + member_num
        {:ok, ~M{state| side1,side1_num}}

      member_num + side2_num <= @side_max ->
        side2 = [team_info | side2]
        side2_num = side2_num + member_num
        {:ok, ~M{state| side2,side2_num}}

      true ->
        {:error, :not_enough_position}
    end
  end

  defp do_join(
         ~M{%Group type,side1,side1_num } = state,
         ~M{member_num} = team_info
       )
       when type == @type_warm do
    cond do
      member_num + side1_num <= @side_max ->
        side1 = [team_info | side1]
        side1_num = side1_num + member_num
        {:ok, ~M{state| side1,side1_num}}

      true ->
        {:error, :not_enough_position}
    end
  end

  defp do_join(
         ~M{%Group _type,side1,side2,side1_num,side2_num} = state,
         ~M{member_num} = team_info
       ) do
    cond do
      member_num + side1_num == @side_max or side1_num == 0 ->
        side1 = [team_info | side1]
        side1_num = side1_num + member_num
        {:ok, ~M{state| side1,side1_num}}

      member_num + side2_num <= @side_max or side2_num == 0 ->
        side2 = [team_info | side2]
        side2_num = side2_num + member_num
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

  def fill_single(~M{%Group base_id,side1_num,side2_num, type} = state) when type == @type_team do
    flag = @side_max - 1

    cond do
      side1_num == flag and side2_num == flag ->
        state

      side1_num == flag and side2_num == @side_max ->
        with [{_match_time, _pool_id, team_id} | _] <-
               Pool.get_team_list({@type_single, base_id}),
             team_info <- Team.Matcher.Team.get(team_id),
             {:ok, state} <- do_join(state, team_info) do
          start(state)
        else
          _ ->
            state
        end

      side1_num == @side_max and side2_num == flag ->
        state

      true ->
        state
    end
  end

  def fill_single(~M{%Group } = state) do
    state
  end

  def start(~M{%Group side1, side2} = state) do
    for ~M{team_id} <- side1 ++ side2 do
      Logger.debug("set match : #{team_id}")

      Team.Matcher.Team.get(team_id)
      |> Team.Matcher.Team.set_match()
      |> Team.Matcher.Team.set()
    end

    Logger.debug("do start #{inspect(state)}")
    state
  end
end
