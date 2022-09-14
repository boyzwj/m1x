defmodule Role.Mod.Battle do
  defstruct role_id: nil, last_battle_time: nil, battle_id: 0
  use Role.Mod

  @expired 30 * 60 * 60
  def on_battle_started(~M{%M } = state, ~M{%Dc.BattleStarted2S battle_id} = msg) do
    Logger.debug(mod: __MODULE__, fun: :on_battle_started, msg: msg)
    last_battle_time = Util.unixtime()
    ~M{state|last_battle_time,battle_id} |> set_data()
  end

  defp on_init(~M{%M battle_id,last_battle_time} = state) do
    with ~M{battle_start_time} <- Dc.get_battle_info(battle_id),
         true <-
           (last_battle_time >= battle_start_time and
              last_battle_time < battle_start_time + @expired) || {:error, :battle_expired} do
      state
    else
      _ ->
        ~M{state|battle_id: 0,last_battle_time: nil} |> set_data()
    end
  end

  def h(~M{%M battle_id: 0}, ~M{%Pbm.Battle.ExitBattle2S }) do
    %Pbm.Battle.ExitBattle2C{} |> sd()
    :ok
  end

  def h(~M{%M role_id,battle_id,last_battle_time} = state, ~M{%Pbm.Battle.ExitBattle2S }) do
    with ~M{battle_start_time} <- Dc.get_battle_info(battle_id),
         true <-
           (last_battle_time >= battle_start_time and
              last_battle_time < battle_start_time + @expired) || {:error, :battle_expired} do
      Dc.Manager.send_to_ds(battle_id, ~M{%Pbm.Dsa.QuitGame2C battle_id, player_id: role_id})
      state
    else
      _ ->
        ~M{state|battle_id: 0,last_battle_time: nil} |> set_data()
    end
  end
end
