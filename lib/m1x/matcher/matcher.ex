defmodule Matcher do
  defstruct team_ids: nil, pool_ids: nil, now: 0
  use Common
  alias Matcher
  alias Matcher.Pool
  alias Matcher.Team, as: MTeam
  alias Matcher.Group
  @max_team_member_count 5
  @loop_interval 1000

  @type_single 1
  @type_team 2
  @type_mix 3
  @type_warm 4

  def init([mode | _]) do
    Logger.debug("start matcher , mode: #{mode}")
    Process.send_after(self(), :loop, @loop_interval)
    pool_ids = init_pool()
    Process.put({__MODULE__, :mode}, mode)
    %Matcher{pool_ids: pool_ids, now: Util.unixtime(), team_ids: MapSet.new()}
  end

  @spec random_map_id :: integer()
  def random_map_id() do
    mode = Process.get({__MODULE__, :mode})
    random_map_by_mode(mode)
  end

  defp random_map_by_mode(mode) do
    Data.GameModeMap.query(&(&1.mode_id == mode))
    |> Enum.map(fn ~M{id,weight} -> List.duplicate(id, weight) end)
    |> Enum.concat()
    |> Util.shuffle()
    |> List.first()
  end

  def init_pool() do
    for base_id <- Data.MatchPool.ids(),
        type <- [@type_single, @type_team, @type_mix, @type_warm] do
      Pool.new(~M{base_id, type})
      |> Pool.set()
      |> Map.get(:id)
    end
  end

  def join(~M{%__MODULE__  now, team_ids} = state, [
        team_id,
        role_ids,
        avg_elo,
        warm
      ])
      when length(role_ids) >= 1 and length(role_ids) <= @max_team_member_count do
    member_num = length(role_ids)

    pool_type =
      cond do
        warm == true -> @type_warm
        member_num == 1 -> @type_single
        true -> @type_team
      end

    base_pool_id = Pool.get_base_id_by_elo(avg_elo)
    pool_id = {pool_type, base_pool_id}

    team_info =
      MTeam.new(~M{team_id,member_num,role_ids,avg_elo,base_pool_id,pool_id,match_time: now})

    Pool.get(pool_id) |> Pool.add_team(team_info) |> Pool.set()
    MTeam.set(team_info)
    team_ids = MapSet.put(team_ids, team_id)
    ~M{state | team_ids} |> reply(:ok)
  end

  def ready_match(~M{%__MODULE__ } = state, [team_id, role_id, reply]) do
    with ~M{%MTeam token} <- MTeam.get(team_id),
         ~M{%Group } = group <- Group.get(token) do
      with :ok <- Group.client_reply(group, [team_id, role_id, reply]) do
        :ok
      else
        {:error, team_id} ->
          cancel_match(state, [team_id])
          Team.Svr.match_canceled(team_id, [role_id])
      end

      state |> reply(:ok)
    else
      _ ->
        state |> reply(:ok)
    end
  end

  def cancel_match(~M{%__MODULE__ team_ids} = state, [team_id]) do
    if not MapSet.member?(team_ids, team_id) do
      throw(:not_in_matching_queue)
    end

    with :ok <- MTeam.delete(team_id) do
      team_ids = MapSet.delete(team_ids, team_id)
      ~M{state | team_ids} |> reply(:ok)
    else
      {:error, msg} ->
        throw(msg)
    end
  end

  def get_pool_infos(~M{%__MODULE__ } = state, _args) do
    pool_infos =
      for base_id <- Data.MatchPool.ids(),
          type <- [@type_single, @type_team, @type_mix, @type_warm] do
        Pool.get({type, base_id})
      end

    reply(state, pool_infos)
  end

  def get_group_infos(~M{%__MODULE__ } = state, _args) do
    group_infos =
      for token <- Group.get_waiting_list() do
        Group.get(token)
      end

    reply(state, group_infos)
  end

  def member_online(~M{%__MODULE__ } = state, [team_id, role_id]) do
    with ~M{%MTeam token} <- MTeam.get(team_id),
         ~M{%Group infos} <- Group.get(token) do
      %Pbm.Team.ReadyMatch2C{infos: infos} |> Role.Misc.send_to(role_id)
      reply(state, :ok)
    else
      _ ->
        reply(state, {:error, "no found group info,role_id: #{role_id},team_id: #{team_id}"})
    end
  end

  def loop(state) do
    Process.send_after(self(), :loop, @loop_interval)
    now = Util.unixtime()

    ~M{state|now}
    |> loop_group()
    |> loop_team()
    |> loop_pool()
  end

  defp loop_team(~M{%Matcher team_ids,now} = state) do
    for team_id <- team_ids do
      MTeam.get(team_id)
      |> MTeam.loop(now)
      |> MTeam.set()
    end

    state
  end

  defp loop_pool(~M{%Matcher pool_ids} = state) do
    for pool_id <- pool_ids do
      Pool.get(pool_id)
      |> Pool.scan()
      |> Pool.set()
    end

    state
  end

  defp loop_group(~M{%Matcher team_ids} = state) do
    # for token <- Group.get_waiting_list() do
    #   Group.get(token) |> Group.loop()
    # end

    # state

    Group.get_waiting_list()
    |> Enum.reduce(state, fn token, state_acc ->
      case Group.get(token) |> Group.loop() do
        {:battle_started, tids} ->
          Enum.each(tids, &MTeam.delete(&1))
          Group.rm_from_waiting_list(token)
          team_ids = Enum.reduce(tids, team_ids, fn x, acc -> MapSet.delete(acc, x) end)
          ~M{state_acc|team_ids}

        {:no_dsa_available, tids} ->
          Enum.each(tids, &MTeam.delete(&1))
          Group.rm_from_waiting_list(token)
          team_ids = Enum.reduce(tids, team_ids, fn x, acc -> MapSet.delete(acc, x) end)
          Enum.each(tids, &Team.Svr.match_canceled(&1, [:by_matcher]))
          ~M{state_acc|team_ids}

        :ignore ->
          state_acc
      end
    end)
  end

  defp reply(state, reply) do
    {reply, state}
  end

  def test3() do
    robot_ids = Bot.Manager.random_bot_by_type(2, 10)
    Matcher.Svr.join(1002, [101, Enum.slice(robot_ids, 0, 1), 1600, false])
    Matcher.Svr.join(1002, [102, Enum.slice(robot_ids, 1, 4), 1670, false])
    Matcher.Svr.join(1002, [103, Enum.slice(robot_ids, 5, 1), 1650, false])
    Matcher.Svr.join(1002, [104, Enum.slice(robot_ids, 6, 4), 1500, false])
  end

  def test_reply() do
    robot_ids = Bot.Manager.random_bot_by_type(2, 10)
    Matcher.Svr.ready_match(1002, [101, Enum.at(robot_ids, 0), 1])
    Matcher.Svr.ready_match(1002, [102, Enum.at(robot_ids, 1), 1])
    Matcher.Svr.ready_match(1002, [102, Enum.at(robot_ids, 2), 1])
    Matcher.Svr.ready_match(1002, [102, Enum.at(robot_ids, 3), 1])
    Matcher.Svr.ready_match(1002, [102, Enum.at(robot_ids, 4), 1])

    Matcher.Svr.ready_match(1002, [103, Enum.at(robot_ids, 5), 1])
    Matcher.Svr.ready_match(1002, [104, Enum.at(robot_ids, 6), 1])
    Matcher.Svr.ready_match(1002, [104, Enum.at(robot_ids, 7), 1])
    Matcher.Svr.ready_match(1002, [104, Enum.at(robot_ids, 8), 1])
    Matcher.Svr.ready_match(1002, [104, Enum.at(robot_ids, 9), 1])
  end

  def test4() do
    role_id = 100_000_001
    {:ok, team_id} = Team.Manager.create_team([role_id, 1002])
    {:ok, _} = Team.Svr.begin_match(team_id, [role_id])
    Team.Svr.name(1001) |> :global.whereis_name() |> :sys.get_state()
    Role.Mod.Team.load(100_000_001)
    robot_ids = Bot.Manager.random_bot_by_type(2, 10)
    Matcher.Svr.join(1002, [101, Enum.slice(robot_ids, 0, 1), 1600, false])
    Process.sleep(1000)
    Matcher.Svr.cancel_match(1002, [101])
  end
end
