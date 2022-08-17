defmodule Team.Matcher.Group do
  defstruct token: nil,
            base_id: 0,
            type: 0,
            side1: [],
            side1_num: 0,
            side2: [],
            side2_num: 0,
            infos: %{},
            all_role_ids: [],
            match_time: 0

  use Common
  alias Team.Matcher.Group
  alias Team.Matcher.Pool
  alias Team.Matcher.Team, as: MTeam
  @type_single 1
  @type_team 2
  @type_mix 3
  @type_warm 4

  @rep_unready 0
  @rep_accept 1
  @rep_refuse 2

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
        with [~M{} = team_info1, ~M{} = team_info2 | _] <-
               Pool.get_waiting_team_list({@type_single, base_id}),
             {:ok, state} <- do_join(state, team_info1),
             {:ok, state} <- do_join(state, team_info2) do
          start(state)
        else
          _ ->
            state
        end

      side1_num == flag and side2_num == @side_max ->
        with [~M{} = team_info | _] <- Pool.get_waiting_team_list({@type_single, base_id}),
             {:ok, state} <- do_join(state, team_info) do
          start(state)
        else
          _ ->
            state
        end

      side1_num == @side_max and side2_num == flag ->
        with [~M{} = team_info | _] <- Pool.get_waiting_team_list({@type_single, base_id}),
             {:ok, state} <- do_join(state, team_info) do
          start(state)
        else
          _ ->
            state
        end

      true ->
        state
    end
  end

  def fill_single(~M{%Group } = state) do
    state
  end

  def start(~M{%Group side1, side2} = state) do
    token = UUID.uuid4()

    all_role_ids =
      for ~M{%MTeam team_id,role_ids} <- side1 ++ side2 do
        Logger.debug("set match : #{team_id}")

        MTeam.get(team_id)
        |> MTeam.set_match(token)
        |> MTeam.set()

        role_ids
      end
      |> Enum.concat()

    infos =
      all_role_ids
      |> Enum.zip_with(0..9, fn role_id, pos ->
        {pos, %Pbm.Team.PositionInfo{role_id: role_id, ready_state: @rep_unready}}
      end)
      |> Enum.into(%{})

    %Pbm.Team.ReadyMatch2C{infos: infos} |> broad_cast(all_role_ids)
    Logger.debug("do start #{inspect(state)}")
    match_time = Util.unixtime()
    ~M{state| token,match_time,infos,all_role_ids} |> add_waiting_list()
  end

  defp broad_cast(msg, role_ids) do
    role_ids |> Enum.each(&Role.Misc.send_to(msg, &1))
  end

  def get_waiting_list() do
    Process.get({__MODULE__, :waiting_list}, [])
  end

  def add_waiting_list(~M{%__MODULE__  token} = state) do
    l = [token | get_waiting_list()]
    Process.put({__MODULE__, :waiting_list}, l)
    set(state)
  end

  def rm_from_waiting_list(token) do
    l = get_waiting_list() |> List.delete(token)
    Process.put({__MODULE__, :waiting_list}, l)
    delete(token)
  end

  def client_reply(~M{%__MODULE__ token,infos,all_role_ids,side1,side2} = _state, [
        cur_team_id,
        cur_role_id,
        @rep_refuse
      ]) do
    infos =
      for {pos, ~M{%Pbm.Team.PositionInfo role_id} = info} <- infos, into: %{} do
        if cur_role_id == role_id do
          {pos, ~M{info| ready_state: @rep_refuse}}
        else
          {pos, info}
        end
      end

    %Pbm.Team.ReadyMatch2C{infos: infos} |> broad_cast(all_role_ids)

    for ~M{%MTeam team_id} <- side1 ++ side2 do
      if team_id != cur_team_id do
        MTeam.get(team_id) |> MTeam.unlock() |> MTeam.set()
      end
    end

    rm_from_waiting_list(token)
    {:error, cur_team_id}
  end

  def client_reply(~M{%__MODULE__ infos,all_role_ids,side1,side2} = state, [
        cur_team_id,
        cur_role_id,
        @rep_accept
      ]) do
    infos =
      for {pos, ~M{%Pbm.Team.PositionInfo role_id} = info} <- infos, into: %{} do
        if cur_role_id == role_id do
          {pos, ~M{info| ready_state: @rep_refuse}}
        else
          {pos, info}
        end
      end

    %Pbm.Team.ReadyMatch2C{infos: infos} |> broad_cast(all_role_ids)
    ~M{state| infos} |> check_all_ready()
    :ok
  end

  def loop(~M{%__MODULE__ side1,side2,token} = state) do
    IO.inspect(state)
  end

  defp check_all_ready(~M{%__MODULE__ } = state) do
    state
  end

  def set(~M{%__MODULE__  token} = state) do
    Process.put({__MODULE__, token}, state)
  end

  def get(token) do
    Process.get({__MODULE__, token})
  end

  def delete(token) do
    Process.delete({__MODULE__, token})
  end
end
