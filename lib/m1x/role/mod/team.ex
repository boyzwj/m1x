defmodule Role.Mod.Team do
  defstruct role_id: nil, team_id: 0, status: 0
  use Role.Mod

  def h(~M{%M team_id} = _state, ~M{%Pbm.Team.Info2S }) do
    if team_id == 0 do
      info = %Pbm.Team.BaseInfo{team_id: 0}
      %Pbm.Team.Info2C{info: info} |> sd()
    else
      ## TODO
      :ok
    end
  end

  def h(~M{%M team_id,role_id} = state, ~M{%Pbm.Team.Create2S mode}) do
    if team_id != 0 do
      throw("已经在队伍里了")
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
      throw("已经退出了")
    end

    with :ok <- Team.Svr.exit_team(team_id, [role_id]) do
      {:ok, ~M{state| team_id: 0}}
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
end
