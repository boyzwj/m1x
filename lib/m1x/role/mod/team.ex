defmodule Role.Mod.Team do
  defstruct role_id: nil, team_id: 0
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
end
