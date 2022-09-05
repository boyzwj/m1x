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

  def exit_team(~M{%Team members,member_num,leader_id,team_id} = state, [role_id]) do
    if not :ordsets.is_element(role_id, role_ids()) do
      state |> ok()
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

      ~M{state| members,member_num,leader_id} |> sync() |> ok()
    end
  end

  def begin_match(~M{%Team team_id,leader_id,status,mode,members} = state, [role_id]) do
    if role_id != leader_id do
      throw("你不是队长")
    end

    if status == @status_battle do
      throw("队伍还在另一场战斗中")
    end

    if state in [@status_matched, @status_matching] do
      throw("队伍已在匹配中")
    end

    avg_elo = get_avg_elo(state)
    Team.Matcher.Svr.join(mode, [team_id, Map.values(members), avg_elo, false])
    state = ~M{state| status: @status_matching} |> sync()
    {{:ok, @status_matching}, state}
  end

  def ready_match(~M{%Team team_id,mode} = state, [role_id, reply]) do
    Team.Matcher.Svr.ready_match(mode, [team_id, role_id, reply])
    {:ok, state}
  end

  def cancel_match(~M{%Team team_id,mode,leader_id} = state, [role_id]) do
    if role_id != leader_id do
      throw("你不是队长")
    end

    Team.Matcher.Svr.cancel_match(mode, [team_id])
    {:ok, state}
  end

  def match_ok(~M{%Team status} = state, []) do
    if status == @status_matching do
      ~M{state|status: @status_matched}
      |> sync()
    end

    {:ok, state}
  end

  def begin_battle(~M{%Team status} = state, []) do
    if status == @status_matched do
      ~M{state|status: @status_battle}
      |> sync()
    end

    {:ok, state}
  end

  def invite_into_team(~M{%Team members,status} = state, [role_id, invitor_id]) do
    if status == @status_battle do
      throw("队伍已在战斗中")
    end

    if state in [@status_matched, @status_matching] do
      throw("队伍已在匹配中")
    end

    member_ids = Map.values(members)

    if !Enum.member?(member_ids, invitor_id) do
      throw("对方已离开该队伍")
    end

    if Enum.member?(member_ids, role_id) do
      throw("已在队伍中")
    end

    add_members(state, role_id) |> sync() |> ok()
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

  defp sync(~M{%Team team_id, leader_id,mode,members,status} = state) do
    info = ~M{%Pbm.Team.BaseInfo  team_id,leader_id,mode,members,status}
    Role.Svr.excute_mod_fun(role_ids(), &Role.Mod.Team.on_sync/2, info)
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
    |> Enum.reduce(fn id, acc ->
      with ~M{elo} <- Role.Mod.Role.load(id) do
        elo + acc
      else
        _ ->
          acc
      end
    end)
    |> div(member_num)
  end
end
