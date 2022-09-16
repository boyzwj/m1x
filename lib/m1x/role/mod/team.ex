defmodule Role.Mod.Team do
  defstruct role_id: nil, team_id: 0
  use Role.Mod

  @reply_refuse 0
  @reply_agree 1

  # def on_sync(~M{%M } = state, ~M{%Pbm.Team.BaseInfo team_id,status} = info) do
  #   Logger.debug(mod: __MODULE__, info: info)

  #   ~M{state|team_id}
  #   |> set_data()

  #   ~M{%Pbm.Team.Info2C info}
  #   |> sd()
  # end

  # 队伍匹配中，断线后，需要退出队伍，同时通知该队伍终止匹配
  defp on_offline(~M{%M team_id,role_id} = state) when team_id > 0 do
    Logger.debug(mod: __MODULE__, fun: "on_offline", status: get_role_status())

    case get_role_status() do
      @role_status_matching ->
        Team.Svr.exit_team(team_id, [role_id])
        set_role_status(@role_status_idle)
        ~M{state|team_id: 0} |> set_data()

      @role_status_idle ->
        h(state, ~M{%Pbm.Team.Exit2S })

      _ ->
        :ok
    end
  end

  defp on_offline(~M{%M }), do: :ok

  defp on_init(~M{%M team_id: 0} = state) do
    if get_role_status() in [@role_status_matching, @role_status_matched] do
      set_role_status(@role_status_idle)
    end

    state
  end

  defp on_init(~M{%M team_id,role_id} = state) do
    IO.inspect(state, label: "on_init team_id != 0 ")

    with {:ok, ~M{%Team status}} <- Team.Svr.get_team_info(team_id, role_id) do
      set_role_status(status)
      state
    else
      {:error, :kicked} ->
        IO.inspect("", label: "kicked")
        set_role_status(@role_status_idle)
        ~M{state|team_id: 0}

      {:error, :team_not_exist} ->
        IO.inspect("", label: "team_not_exist")
        set_role_status(@role_status_idle)
        ~M{state|team_id: 0}

      error ->
        Logger.error("unknow error: #{inspect(error)}")
        set_role_status(@role_status_idle)
        ~M{state|team_id: 0}
    end
  end

  def role_status_change(~M{%M}, @role_status_idle, :begin_match = msg) do
    Logger.debug(mod: __MODULE__, fun: :role_status_change, msg: inspect(msg))
    set_role_status(@role_status_matching)
    :ok
  end

  def role_status_change(~M{%M}, @role_status_matching, :match_ok = msg) do
    Logger.debug(mod: __MODULE__, fun: :role_status_change, msg: inspect(msg))
    set_role_status(@role_status_matched)
    :ok
  end

  def role_status_change(_, _, _), do: :ok

  def h(~M{%M team_id: 0} = _state, ~M{%Pbm.Team.Info2S }) do
    info = ~M{%Pbm.Team.BaseInfo team_id: 0}
    ~M{%Pbm.Team.Info2C info} |> sd()
    :ok
  end

  def h(~M{%M team_id,role_id} = _state, ~M{%Pbm.Team.Info2S }) do
    with {:ok, ~M{%Team leader_id,members,status,mode}} <-
           Team.Svr.get_team_info(team_id, role_id) do
      info = ~M{%Pbm.Team.BaseInfo team_id,leader_id,mode,members,status}
      ~M{%Pbm.Team.Info2C info} |> sd()

      if get_role_status() == @role_status_matched do
        # TODO 队伍匹配完成，断线重连后，需要同步匹配状态至该玩家
        Team.Svr.member_online(team_id, [role_id])
      end

      :ok
    else
      {:error, error} ->
        throw(error)
    end
  end

  def h(~M{%M team_id,role_id} = state, ~M{%Pbm.Team.Create2S mode}) do
    if team_id != 0 do
      throw("已经在队伍里了")
    end

    status = get_role_status()

    if status == @role_status_battle do
      throw("你当前还在另一场战斗中,请先退出战斗，才能创建队伍")
    end

    with {:ok, team_id} <- Team.Manager.create_team([role_id, mode]) do
      ~M{%Pbm.Team.Create2C mode,team_id} |> sd()
      {:ok, ~M{state|team_id}}
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
        :ok
      else
        {:error, error} ->
          throw(error)
      end
    end
  end

  def h(~M{%M team_id, role_id} = state, ~M{%Pbm.Team.Exit2S }) do
    if team_id == 0 do
      throw("你已经退出了")
    end

    status = get_role_status()

    if status == @role_status_battle do
      throw("你当前还在另一场战斗中,请先退出战斗，才能退出队伍")
    end

    if status == @role_status_matched do
      throw("你当前队伍匹配成功，无法退出队伍")
    end

    with :ok <- Team.Svr.exit_team(team_id, [role_id, status]) do
      set_role_status(@role_status_idle)
      {:ok, ~M{state| team_id: 0}}
    else
      {:error, error} ->
        throw(error)
    end
  end

  def h(~M{%M team_id, role_id} = _state, ~M{%Pbm.Team.BeginMatch2S }) do
    if team_id == 0 do
      throw("你不在一个队伍中")
    end

    status = get_role_status()

    if status == @role_status_matching do
      throw("你当前正在匹配中")
    end

    if status == @role_status_matched do
      throw("你当前队伍匹配成功")
    end

    if status == @role_status_battle do
      throw("你当前还在另一场战斗中")
    end

    with :ok <- Team.Svr.begin_match(team_id, [role_id]) do
      :ok
    else
      {:error, error} ->
        throw(error)
    end
  end

  def h(~M{%M team_id, role_id} = _state, ~M{%Pbm.Team.ReadyMatch2S reply}) do
    if team_id == 0 do
      throw("你不在一个队伍中")
    end

    status = get_role_status()

    if status == @role_status_idle do
      throw("尚未完成匹配")
    end

    if status == @role_status_matching do
      throw("正在匹配中")
    end

    if status == @role_status_battle do
      throw("还在另一场战斗中")
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

  def h(~M{%M team_id, role_id: invitor_id}, ~M{%Pbm.Team.Invite2S role_id}) do
    if team_id == 0 do
      throw("你不在一个队伍中")
    end

    if role_id == invitor_id do
      throw("不能邀请自己")
    end

    status = get_role_status()

    if status in [@role_status_matched, @role_status_matching] do
      throw("已在匹配中")
    end

    if !Role.Svr.alive?(role_id) do
      throw("被邀请者已离线")
    end

    {:ok, ~M{%Team mode}} = Team.Svr.get_team_info(team_id, invitor_id)
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

    if old_team_id != 0 && old_team_id == team_id do
      throw("已在队伍中")
    end

    status = get_role_status()

    if status == @role_status_battle do
      throw("已在另一场战斗中")
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
