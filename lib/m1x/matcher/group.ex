defmodule Matcher.Group do
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
  alias Matcher.Group
  alias Matcher.Pool
  alias Matcher.Team, as: MTeam
  @type_single 1
  @type_team 2
  @type_mix 3
  @type_warm 4

  @rep_unready 0
  @rep_accept 1
  @rep_refuse 2

  @side_max 5

  @room_type_free 1
  @room_type_match 2

  @robot_type_room 1
  @robot_type_fakeman 2
  @robot_type_npc 3

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

        if team_id > 0 do
          MTeam.get(team_id)
          |> MTeam.set_match(token)
          |> MTeam.set()
        end

        role_ids
      end
      |> Enum.concat()

    infos =
      all_role_ids
      |> Enum.zip_with(0..9, fn role_id, pos ->
        read_state =
          if Bot.Manager.is_robot_id(role_id) do
            @rep_accept
          else
            @rep_unready
          end

        {pos, %Pbm.Team.PositionInfo{role_id: role_id, ready_state: read_state}}
      end)
      |> Enum.into(%{})

    Enum.map(side1, &Team.Svr.match_ok(&1.team_id, []))
    Enum.map(side2, &Team.Svr.match_ok(&1.team_id, []))

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

  # TODO 匹配完成期间，任意拒绝准备，通知本队伍状态为idle，其它队伍状态为matching
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

  def client_reply(~M{%__MODULE__ infos,all_role_ids} = state, [
        cur_team_id,
        cur_role_id,
        @rep_accept
      ]) do
    IO.inspect("reply accept")

    infos =
      for {pos, ~M{%Pbm.Team.PositionInfo role_id} = info} <- infos, into: %{} do
        if cur_role_id == role_id do
          {pos, ~M{info| ready_state: @rep_accept}}
        else
          {pos, info}
        end
      end

    %Pbm.Team.ReadyMatch2C{infos: infos} |> broad_cast(all_role_ids)
    ~M{state| infos} |> set()
    :ok
  end

  def loop(~M{%__MODULE__ } = state) do
    # IO.inspect(infos)
    check_all_ready(state)
  end

  defp check_all_ready(~M{%__MODULE__ all_role_ids, infos} = state) do
    ready_ids =
      for {_pos, ~M{ready_state,role_id}} when ready_state == @rep_accept <- infos,
          into: MapSet.new() do
        role_id
      end

    with true <- Enum.all?(all_role_ids, &MapSet.member?(ready_ids, &1)),
         {:ok, team_ids} <- begin_to_start(state) do
      {:battle_started, team_ids}
    else
      {:no_dsa_available, team_ids} ->
        {:no_dsa_available, team_ids}

      _ ->
        :ignore
    end
  end

  def begin_to_start(~M{%__MODULE__  all_role_ids,token,side1,side2}) do
    # map_id = 10_051_068
    map_id = Matcher.random_map_id()

    team_ids = (side1 ++ side2) |> Enum.map(& &1.team_id)
    ext = ~M{team_ids}
    role_id = List.first(all_role_ids)

    with {:ok, room_id} <-
           Lobby.Svr.create_room([@room_type_match, all_role_ids, map_id, token, ~M{ext}]),
         :ok <- Lobby.Room.Svr.start_game(room_id, role_id) do
      {:ok, team_ids}
    else
      {:error, :no_dsa_available} = error ->
        Logger.error("start match room error : #{inspect(error)}")
        {:no_dsa_available, team_ids}

      error ->
        Logger.error("start match room error : #{inspect(error)}")
        :ignore
    end
  end

  def join_robot(~M{%__MODULE__ side1,side2,base_id, type} = state) do
    ~M{multiplayer_bot,single_bot,ai_id} = Data.MatchPool.get(base_id)
    now = Util.unixtime()

    cond do
      ai_id > 0 && type == @type_single ->
        if (side1 ++ side2) |> Enum.any?(&(now - &1.match_time >= single_bot)) do
          do_join_robot(state)
        else
          state
        end

      ai_id > 0 ->
        if (side1 ++ side2) |> Enum.any?(&(now - &1.match_time >= multiplayer_bot)) do
          do_join_robot(state)
        else
          state
        end

      true ->
        state
    end
  end

  defp do_join_robot(~M{%__MODULE__ side1,side1_num,side2,side2_num} = state) do
    need_num = @side_max * 2 - (side1_num + side2_num)

    if need_num > 0 do
      bot_ids = Bot.Manager.random_bot_by_type(@robot_type_fakeman, need_num)
      side1_need = @side_max - side1_num
      {side1_bots, side2_bots} = Enum.split(bot_ids, side1_need)
      side1 = [%MTeam{role_ids: side1_bots, member_num: length(side1_bots)} | side1]
      side2 = [%MTeam{role_ids: side2_bots, member_num: length(side2_bots)} | side2]
      ~M{state | side1,side2,side1_num: @side_max,side2_num: @side_max}
    else
      state
    end
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
