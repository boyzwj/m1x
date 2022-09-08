defmodule Team.Matcher.Team do
  defstruct team_id: 0,
            token: nil,
            member_num: 0,
            role_ids: [],
            avg_elo: 0,
            match_time: 0,
            next_jump_up_time: 0,
            jump_up_left: 0,
            next_jump_down_time: 0,
            jump_down_left: 0,
            jump_mix_time: 0,
            in_mix?: false,
            pool_id: 0,
            pool_ids: [],
            status: 0

  use Common

  @type_single 1
  @type_team 2
  @type_mix 3
  @type_warm 4

  @status_waiting 0
  @status_matched 1

  alias Team.Matcher.Pool

  def new(~M{team_id,member_num,role_ids,avg_elo,match_time,pool_id}) do
    status = @status_waiting
    {_type, base_pool_id} = pool_id

    pool_ids = [pool_id]
    ~M{timeup,across_frequency,blend_time} = Data.MatchPool.get(base_pool_id)
    next_jump_up_time = match_time + timeup
    next_jump_down_time = match_time + timeup
    jump_up_left = across_frequency
    jump_down_left = across_frequency
    jump_mix_time = match_time + blend_time

    %__MODULE__{
      team_id: team_id,
      member_num: member_num,
      role_ids: role_ids,
      avg_elo: avg_elo,
      pool_id: pool_id,
      pool_ids: pool_ids,
      match_time: match_time,
      jump_mix_time: jump_mix_time,
      next_jump_up_time: next_jump_up_time,
      jump_up_left: jump_up_left,
      next_jump_down_time: next_jump_down_time,
      jump_down_left: jump_down_left,
      status: status
    }
  end

  def loop(~M{%__MODULE__ status} = state, _now) when status == @status_matched, do: state

  def loop(~M{%__MODULE__ in_mix?} = state, _now) when in_mix?, do: state

  def loop(~M{%__MODULE__ } = state, now) do
    state
    |> check_jump_up(now)
    |> check_jump_down(now)
    |> check_jump_mix(now)
  end

  defp check_jump_up(~M{%__MODULE__ next_jump_up_time, jump_up_left} = state, now) do
    if now >= next_jump_up_time && jump_up_left > 0 do
      do_jump_up(state, now)
    else
      state
    end
  end

  defp check_jump_down(~M{%__MODULE__ next_jump_down_time, jump_down_left} = state, now) do
    if now >= next_jump_down_time && jump_down_left > 0 do
      do_jump_down(state, now)
    else
      state
    end
  end

  defp check_jump_mix(~M{%__MODULE__ pool_id, jump_mix_time} = state, now) do
    {type, _} = pool_id
    # IO.inspect({now, jump_mix_time})

    if now >= jump_mix_time && type != @type_warm do
      do_jump_mix(state, now)
    else
      state
    end
  end

  defp do_jump_up(
         ~M{%__MODULE__ team_id, pool_id,jump_up_left,pool_ids,status} = state,
         now
       ) do
    Logger.debug("team_id: #{team_id} , status: #{status} ,do jump up:  #{inspect(pool_ids)}")
    {_, base_pool_id} = pool_id
    ~M{timeup,across} = Data.MatchPool.get(base_pool_id)
    next_jump_up_time = now + timeup
    jump_up_left = jump_up_left - 1
    {type, uppest_pool_id} = pool_ids |> Enum.sort(:desc) |> List.first()

    for base_jump_id <- (uppest_pool_id + 1)..(uppest_pool_id + across),
        Data.MatchPool.get(base_jump_id) != nil do
      {type, base_jump_id}
    end
    |> Enum.reduce(
      ~M{state | next_jump_up_time, jump_up_left},
      fn jump_pool_id, ~M{pool_ids} = acc ->
        pool_ids = [jump_pool_id | pool_ids]

        Pool.get(jump_pool_id)
        |> Pool.add_team(acc)
        |> Pool.set()

        ~M{acc|pool_ids}
      end
    )
  end

  defp do_jump_down(
         ~M{%__MODULE__ pool_id,jump_down_left,pool_ids} = state,
         now
       ) do
    Logger.debug("do jump down: #{inspect(pool_ids)}")
    {_, base_pool_id} = pool_id
    ~M{timeup,across} = Data.MatchPool.get(base_pool_id)
    next_jump_down_time = now + timeup
    jump_down_left = jump_down_left - 1
    {type, lowest_pool_id} = pool_ids |> Enum.sort() |> List.first()

    for base_jump_id <- (lowest_pool_id - across)..(lowest_pool_id - 1),
        Data.MatchPool.get(base_jump_id) != nil do
      {type, base_jump_id}
    end
    |> Enum.reduce(
      ~M{state | next_jump_down_time, jump_down_left},
      fn jump_pool_id, ~M{pool_ids} = acc ->
        pool_ids = [jump_pool_id | pool_ids]

        Pool.get(jump_pool_id)
        |> Pool.add_team(acc)
        |> Pool.set()

        ~M{acc|pool_ids}
      end
    )
  end

  defp do_jump_mix(~M{%__MODULE__ team_id,pool_ids} = state, _now) do
    state = ~M{state| pool_ids: []}

    pool_ids =
      for {_type, base_bool_id} = pool_id <- pool_ids do
        Pool.get(pool_id)
        |> Pool.remove_team(team_id)
        |> Pool.set()

        new_pool_id = {@type_mix, base_bool_id}

        Pool.get(new_pool_id)
        |> Pool.add_team(state)
        |> Pool.set()

        new_pool_id
      end

    Logger.debug("join to mix #{inspect(pool_ids)}")
    ~M{state| pool_ids,in_mix?: true}
  end

  def get(team_id) do
    Process.get({__MODULE__, team_id})
  end

  def set(~M{%__MODULE__ team_id} = team) do
    Process.put({__MODULE__, team_id}, team)
  end

  def set_match(state, token) do
    status = @status_matched
    ~M{state| status,token}
  end

  def unlock(state) do
    status = @status_waiting
    ~M{state| status,token: nil}
  end

  def matched?(~M{status}) do
    status == @status_matched
  end

  def delete(team_id) do
    Process.delete({__MODULE__, team_id})
  end
end
