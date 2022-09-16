defmodule Team do
  defstruct team_id: 0, leader_id: 0, mode: 0, members: %{}, status: 0, member_num: 0
  use Common

  @positions [0, 1, 2, 3, 4]

  @status_idle 0
  @status_matching 1
  @status_matched 2
  @status_battle 3

  def init([team_id, leader_id, mode]) do
    %Team{team_id: team_id, leader_id: leader_id, mode: mode, status: @status_idle}
    |> add_members(leader_id)
    |> sync()
  end

  def add_members(~M{%Team member_num,members} = state, role_id) do
    pos = find_free_pos(state)
    members = members |> Map.put(pos, role_id)
    add_role_id(role_id)
    member_num = member_num + 1
    ~M{state | member_num ,members}
  end

  def change_mode(~M{%Team leader_id} = state, [role_id, mode]) do
    if role_id != leader_id do
      throw("你不是队长")
    end

    ~M{state|mode}
    |> sync()
    |> ok()
  end

  def exit_team(~M{%Team status: @status_matching} = state, [role_id]) do
    with {:ok, state} <- do_cancel_match(state, role_id),
         {:ok, ~M{%Team } = state} <- do_exit_team(state, [role_id]) do
      ~M{state| status: @status_idle}
      |> sync()
      |> ok()
    else
      {:error, msg} ->
        throw(msg)
    end
  end

  def exit_team(~M{%Team status: @status_idle} = state, [role_id]) do
    with {:ok, state} <- do_exit_team(state, [role_id]) do
      state |> sync() |> ok()
    else
      {:error, msg} ->
        throw(msg)
    end
  end

  def exit_team(~M{%Team } = state, [role_id, @role_status_idle]) do
    with {:ok, state} <- do_exit_team(state, [role_id]) do
      Logger.debug("role[#{role_id}] exit team[#{state.team_id}] success")

      state |> sync() |> ok()
    else
      {:error, msg} ->
        throw(msg)
    end
  end

  def exit_team(~M{%Team status: @status_battle}, _) do
    throw("队伍还在另一场战斗中,无法退出队伍")
  end

  def exit_team(~M{%Team status: @status_matched}, _) do
    throw("队伍匹配成功，无法退出队伍")
  end

  defp do_exit_team(~M{%Team members,member_num,leader_id,team_id} = state, [role_id]) do
    if not :ordsets.is_element(role_id, role_ids()) do
      {:error, "已经退出队伍了"}
    else
      members =
        for {k, v} <- members, v != role_id, into: %{} do
          {k, v}
        end

      ~M{%Pbm.Team.Exit2C team_id,role_id} |> broad_cast()
      member_num = member_num - 1
      del_role_id(role_id)

      leader_id =
        if role_id == leader_id do
          role_ids() |> Util.rand_list() || 0
        else
          leader_id
        end

      if member_num == 0 do
        self() |> Process.send(:shutdown, [:nosuspend])
      end

      {:ok, ~M{state| members,member_num,leader_id}}
    end
  end

  def begin_match(~M{%Team team_id,leader_id,status,mode,members} = state, [role_id]) do
    if role_id != leader_id do
      throw("你不是队长")
    end

    if status == @status_battle do
      throw("队伍还在另一场战斗中")
    end

    if status in [@status_matched, @status_matching] do
      throw("队伍已在匹配中")
    end

    avg_elo = get_avg_elo(state)
    role_ids = Map.values(members)
    Team.Matcher.Svr.join(mode, [team_id, role_ids, avg_elo, false])

    ~M{state| status: @status_matching}
    |> sync_role_status(:begin_match)
    |> sync()
    |> ok()
  end

  def ready_match(~M{%Team team_id,mode,status} = state, [role_id, reply]) do
    if status == @status_battle do
      throw("队伍还在另一场战斗中")
    end

    if status == @status_matching do
      throw("队伍正在匹配中")
    end

    Team.Matcher.Svr.ready_match(mode, [team_id, role_id, reply])
    {:ok, state}
  end

  def cancel_match(~M{%Team leader_id} = state, [role_id]) do
    if role_id != leader_id do
      throw("你不是队长")
    end

    with {:ok, state} <- do_cancel_match(state, role_id) do
      state |> sync() |> ok()
    else
      {:error, msg} ->
        throw(msg)
    end
  end

  def member_online(~M{%Team mode,team_id} = state, [role_id]) do
    Team.Matcher.Svr.member_online(mode, [team_id, role_id])
    state |> ok()
  end

  def match_ok(~M{%Team status} = state, []) do
    Logger.debug(mod: "match_ok", info: state)

    if status == @status_matching do
      ~M{state|status: @status_matched}
      |> sync_role_status(:match_ok)
      |> sync()
      |> ok()
    else
      {:ok, state}
    end
  end

  def begin_battle(~M{%Team status} = state, []) do
    if status == @status_matched do
      ~M{state|status: @status_battle}
      |> sync()
      |> ok()
    else
      {:ok, state}
    end
  end

  def battle_closed(~M{%Team status} = state, [reason]) do
    if status in [@status_matched, @status_battle] do
      Logger.debug("battle close for reason: #{reason}")

      ~M{state|status: @status_idle}
      |> sync()
      |> ok()
    else
      {:ok, state}
    end
  end

  def invite_into_team(~M{%Team members,status} = state, [role_id, invitor_id]) do
    if status == @status_battle do
      throw("队伍已在战斗中")
    end

    if status in [@status_matched, @status_matching] do
      throw("队伍已在匹配中")
    end

    member_ids = Map.values(members)

    if Enum.member?(member_ids, role_id) do
      throw("已在队伍中")
    end

    if !Enum.member?(member_ids, invitor_id) do
      throw("对方已离开该队伍")
    end

    add_members(state, role_id) |> sync() |> ok()
  end

  def get_team_info(~M{%Team members} = state, role_id) do
    with true <- Enum.member?(Map.values(members), role_id) || {:error, :kicked} do
      {{:ok, state}, state}
    else
      error ->
        {error, state}
    end
  end

  def match_canceled(~M{%Team members} = state, [role_id]) do
    if !Enum.member?(members, role_id) do
      throw("玩家已不再该队伍")
    end

    # TODO 广播消息： [玩家名]未进行匹配确认，匹配中断
    ~M{state|status: @status_idle} |> sync() |> ok()
  end

  defp find_free_pos(state, poses \\ @positions)
  defp find_free_pos(_state, []), do: throw("没有空余的位置了")

  defp find_free_pos(~M{%Team members} = state, [pos | t]) do
    if members[pos] == nil do
      pos
    else
      find_free_pos(state, t)
    end
  end

  def set_dirty(dirty) do
    Process.put({__MODULE__, :dirty}, dirty)
  end

  defp dirty?() do
    Process.get({__MODULE__, :dirty}, false)
  end

  defp role_ids() do
    Process.get({__MODULE__, :role_ids}, [])
  end

  defp set_role_ids(ids) do
    Process.put({__MODULE__, :role_ids}, ids)
  end

  defp add_role_id(role_id) do
    :ordsets.add_element(role_id, role_ids())
    |> set_role_ids()
  end

  # defp sync(~M{%Team team_id, leader_id,mode,members,status} = state) do
  #   info = ~M{%Pbm.Team.BaseInfo  team_id,leader_id,mode,members,status}
  #   Role.Svr.execute_mod_fun(role_ids(), &Role.Mod.Team.on_sync/2, info)
  #   state
  # end

  defp sync(~M{%Team team_id, leader_id,mode,members,status} = state) do
    info = ~M{%Pbm.Team.BaseInfo  team_id,leader_id,mode,members,status}
    ~M{%Pbm.Team.Info2C info} |> broad_cast()
    state
  end

  defp sync_role_status(~M{%Team members} = state, event) do
    Map.values(members)
    |> Enum.each(&Role.Svr.role_status_change(&1, event))

    state
  end

  defp del_role_id(role_id) do
    :ordsets.del_element(role_id, role_ids())
    |> set_role_ids()
  end

  def broad_cast(state, msg) do
    broad_cast(msg)
    state |> ok()
  end

  defp broad_cast(msg) do
    role_ids()
    |> Enum.each(&Role.Misc.send_to(msg, &1))
  end

  defp ok(state), do: {:ok, state}

  defp get_avg_elo(~M{%Team member_num}) do
    role_ids()
    |> Enum.reduce(0, fn id, acc ->
      with ~M{elo} <- Role.Mod.Role.load(id) do
        elo + acc
      else
        _ ->
          acc
      end
    end)
    |> div(member_num)
  end

  defp do_cancel_match(~M{%Team status: @status_battle}, _role_id),
    do: {:error, "队伍还在另一场战斗中，无法取消匹配"}

  defp do_cancel_match(~M{%Team status: @status_matched}, _role_id), do: {:error, "队伍匹配完成，无法取消匹配"}

  defp do_cancel_match(~M{%Team team_id,mode,status} = state, role_id) do
    with :ok <- Team.Matcher.Svr.cancel_match(mode, [team_id]) do
      if status == @status_matching do
        # TODO 广播消息： [玩家名]退出了PARTY，匹配中断
        Logger.debug(cancel_match: "广播消息： #{role_id} 退出了team: #{team_id}，匹配中断")
      end

      {:ok, ~M{state|status: @status_idle}}
    else
      {:error, msg} ->
        {:error, msg}
    end
  end
end
