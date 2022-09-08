defmodule Role.Mod.Team do
  defstruct role_id: nil, team_id: 0, status: 0, mode: 0
  use Role.Mod

  @status_idle 0
  @status_matching 1
  @status_matched 2
  @status_battle 3

  @reply_refuse 0
  @reply_agree 1

  def on_sync(~M{%M } = state, ~M{%Pbm.Team.BaseInfo team_id,status,mode} = info) do
    Logger.debug(mod: __MODULE__, info: info)

    ~M{state|status,mode,team_id}
    |> set_data()

    ~M{%Pbm.Team.Info2C info}
    |> sd()
  end

  # 队伍匹配中，断线后，需要退出队伍，同时通知该队伍终止匹配
  defp on_offline(~M{%M team_id,role_id,status: @status_matching} = state) when team_id > 0 do
    Logger.debug(mod: __MODULE__, info: "on_offline")

    Team.Svr.member_offline(team_id, [role_id])
    ~M{state|team_id: 0,status: @status_idle,mode: 0} |> set_data()
  end

  defp on_offline(~M{%M team_id,status: @status_idle} = state) when team_id > 0 do
    Logger.debug(mod: __MODULE__, info: "on_offline", stateus: @status_idle)
    h(state, ~M{%Pbm.Team.Exit2S })
  end

  defp on_offline(~M{%M }), do: :ok

  defp on_init(~M{%M team_id,role_id} = state) when team_id != 0 do
    IO.inspect(state, label: "on_init team_id != 0 ")

    with {:ok, ~M{%Team status,mode}} <- Team.Svr.get_team_info(team_id, role_id) do
      ~M{state|status,mode}
    else
      {:error, :kicked} ->
        IO.inspect("", label: "kicked")
        ~M{state|team_id: 0,status: @status_idle,mode: 0}

      {:error, :room_not_exist} ->
        IO.inspect("", label: "room_not_exist")
        ~M{state|team_id: 0,status: @status_idle,mode: 0}

      error ->
        Logger.error("unknow error: #{inspect(error)}")
        state
    end
  end

  defp on_init(~M{%M } = state), do: state |> IO.inspect(label: "on_init  team_id == 0 ")

  def h(~M{%M team_id,status,role_id,mode} = _state, ~M{%Pbm.Team.Info2S }) do
    cond do
      team_id == 0 ->
        info = ~M{%Pbm.Team.BaseInfo team_id}
        ~M{%Pbm.Team.Info2C info} |> sd()
        :ok

      status == @status_matched ->
        # 队伍匹配完成，断线重连后，需要同步匹配状态至该玩家
        {:ok, ~M{%Team leader_id,members}} = Team.Svr.get_team_info(team_id, role_id)
        Team.Svr.member_online(team_id, [role_id])
        info = ~M{%Pbm.Team.BaseInfo team_id,leader_id,mode,members,status}
        ~M{%Pbm.Team.Info2C info} |> sd()
        :ok

      status == @status_battle ->
        # 队伍战斗，断线重连后，需要同步战斗状态至该玩家
        # {:ok, ~M{%Team leader_id,members}} = Team.Svr.get_team_info(team_id, role_id)
        # info = ~M{%Pbm.Team.BaseInfo team_id,leader_id,mode,members,status}
        # ~M{%Pbm.Team.Info2C info} |> sd()
        :ok

      true ->
        :ok
    end
  end

  def h(~M{%M team_id,role_id} = state, ~M{%Pbm.Team.Create2S mode}) do
    if team_id != 0 do
      throw("已经在队伍里了")
    end

    with {:ok, team_id} <- Team.Manager.create_team([role_id, mode]) do
      ~M{%Pbm.Team.Create2C mode,team_id} |> sd()
      {:ok, ~M{state|team_id,mode}}
    else
      {:error, error} ->
        throw(error)
    end
  end

  def h(~M{%M team_id,role_id} = state, ~M{%Pbm.Team.ChangeMode2S mode}) do
    if team_id == 0 do
      h(state, ~M{%Pbm.Team.Create2S mode})
    else
      with :ok <- Team.Svr.change_mode(team_id, [role_id, mode]) do
        {:ok, ~M{state|mode}}
      else
        {:error, error} ->
          throw(error)
      end
    end
  end

  def h(~M{%M team_id, role_id} = state, ~M{%Pbm.Team.Exit2S }) do
    if team_id == 0 do
      throw("已经退出了")
    end

    with :ok <- Team.Svr.exit_team(team_id, [role_id]) do
      {:ok, ~M{state| team_id: 0,status: 0, mode: 0}}
    else
      {:error, error} ->
        throw(error)
    end
  end

  def h(~M{%M team_id, role_id} = state, ~M{%Pbm.Team.BeginMatch2S }) do
    if team_id == 0 do
      throw("你不在一个队伍中")
    end

    with {:ok, status} <- Team.Svr.begin_match(team_id, [role_id]) do
      {:ok, ~M{state| status}}
    else
      {:error, error} ->
        throw(error)
    end
  end

  def h(~M{%M team_id, role_id,status} = _state, ~M{%Pbm.Team.ReadyMatch2S reply}) do
    if team_id == 0 do
      throw("你不在一个队伍中")
    end

    if status == @status_battle do
      throw("队伍还在另一场战斗中")
    end

    if status == @status_matching do
      throw("队伍正在匹配中")
    end

    Team.Svr.ready_match(team_id, [role_id, reply])
  end

  def h(~M{%M team_id, role_id} = _state, ~M{%Pbm.Team.CancelMatch2S }) do
    with true <- team_id != 0 || {:error, "你不在一个队伍中"},
         :ok <- Team.Svr.cancel_match(team_id, [role_id]) do
      :ok
    else
      {:error, error} ->
        throw(error)
    end
  end

  def h(~M{%M team_id, role_id: invitor_id,status,mode}, ~M{%Pbm.Team.Invite2S role_id}) do
    if team_id == 0 do
      throw("你不在一个队伍中")
    end

    if role_id == invitor_id do
      throw("不能邀请自己")
    end

    if status in [@status_matched, @status_matching] do
      throw("队伍已在匹配中")
    end

    if !Role.Svr.alive?(role_id) do
      throw("被邀请者不在线")
    end

    ~M{%Pbm.Team.InviteRequest2C invitor_id,mode,team_id} |> Role.Misc.send_to(role_id)
    ~M{%Pbm.Team.Invite2C role_id} |> sd()
    :ok
  end

  def h(~M{%M  role_id} = _state, ~M{%Pbm.Team.InviteReply2S reply,invitor_id})
      when reply == @reply_refuse do
    ~M{%Pbm.Team.InviteReply2C role_id,reply} |> Role.Misc.send_to(invitor_id)
    :ok
  end

  def h(
        ~M{%M role_id,team_id: old_team_id} = state,
        ~M{%Pbm.Team.InviteReply2S team_id,reply,invitor_id}
      )
      when reply == @reply_agree do
    if team_id == 0 do
      throw("队伍id不能为空")
    end

    if old_team_id != 0 && old_team_id != team_id do
      throw("已经在其他队伍")
    end

    with :ok <- Team.Svr.invite_into_team(team_id, [role_id, invitor_id]) do
      ~M{%Pbm.Team.InviteReply2C role_id,reply} |> Role.Misc.send_to(invitor_id)
      {:ok, ~M{state|team_id}}
    else
      {:error, error} ->
        throw(error)
    end
  end
end
