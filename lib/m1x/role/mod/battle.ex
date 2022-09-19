defmodule Role.Mod.Battle do
  defstruct role_id: nil, last_battle_time: 0, battle_id: 0
  use Role.Mod

  @expired 30 * 60 * 60
  @room_type_free 1
  @room_type_match 2

  defp on_init(~M{%M battle_id,last_battle_time} = state) do
    with ~M{battle_start_time} <- Dc.get_battle_info(battle_id),
         true <-
           (last_battle_time >= battle_start_time and
              last_battle_time < battle_start_time + @expired) || {:error, :battle_expired} do
      state
    else
      {:error, :battle_expired} ->
        Logger.debug("battle was expired.battle_id: #{battle_id}")
        ~M{state|battle_id: 0,last_battle_time: 0}

      _ ->
        ~M{state|battle_id: 0,last_battle_time: 0}
    end
  end

  # TODO 如果没接收到battle_id,上线后还需从其room或team中获取？
  def on_battle_started(~M{%M } = state, ~M{%Dc.BattleStarted2S battle_id} = msg) do
    Logger.debug(mod: __MODULE__, fun: :on_battle_started, msg: msg)
    last_battle_time = Util.unixtime()
    ~M{state|last_battle_time,battle_id} |> set_data()
  end

  def role_status_change(
        ~M{%M battle_id: old_battle_id,last_battle_time} = state,
        @role_status_battle,
        ~M{%Pbm.Dsa.PlayerQuit2S battle_id} = msg
      )
      when old_battle_id != 0 do
    Logger.debug(mod: __MODULE__, fun: :role_status_change, msg: inspect(msg))

    with true <- battle_id == old_battle_id || {:error, :expired_battle},
         ~m{battle_start_time} <- Dc.get_battle_info(battle_id),
         true <-
           (last_battle_time >= battle_start_time and
              last_battle_time < battle_start_time + @expired) || {:error, :battle_expired} do
      set_role_status(@role_status_idle)
      %Pbm.Battle.ExitBattle2C{} |> sd()
      ~M{state|battle_id: 0,last_battle_time: 0} |> set_data()
    else
      {:error, reason} ->
        Logger.debug(
          "battle role_status_change fail for reason: [#{reason}],battle_id: [#{battle_id}]"
        )

        set_role_status(@role_status_idle)
        ~M{state|battle_id: 0,last_battle_time: 0} |> set_data()

      _ ->
        Logger.debug(
          "battle role_status_change fail for reason: [battle_is_none],battle_id: [#{battle_id}]"
        )

        set_role_status(@role_status_idle)
        ~M{state|battle_id: 0,last_battle_time: 0} |> set_data()
    end
  end

  def role_status_change(~M{%M}, @role_status_idle, {:battle_start, @room_type_free} = msg) do
    Logger.debug(mod: __MODULE__, fun: :role_status_change, msg: inspect(msg))
    set_role_status(@role_status_battle)
    :ok
  end

  def role_status_change(~M{%M}, @role_status_matched, {:battle_start, @room_type_match} = msg) do
    Logger.debug(mod: __MODULE__, fun: :role_status_change, msg: inspect(msg))
    set_role_status(@role_status_battle)
    :ok
  end

  # TODO战斗结算处理地方
  def role_status_change(~M{%M}, @role_status_battle, {:battle_closed, _, :battle_finish} = msg) do
    Logger.debug(mod: __MODULE__, fun: :role_status_change, msg: inspect(msg))
    set_role_status(@role_status_idle)
    :ok
  end

  def role_status_change(~M{%M}, @role_status_battle, {:battle_closed, _, _} = msg) do
    Logger.debug(mod: __MODULE__, fun: :role_status_change, msg: inspect(msg))
    set_role_status(@role_status_idle)
    :ok
  end

  def role_status_change(_, _, _) do
    :ok
  end

  def h(~M{%M battle_id: 0}, ~M{%Pbm.Battle.ExitBattle2S }) do
    %Pbm.Battle.ExitBattle2C{} |> sd()
    :ok
  end

  def h(~M{%M role_id,battle_id,last_battle_time} = state, ~M{%Pbm.Battle.ExitBattle2S }) do
    with ~m{battle_start_time} <- Dc.get_battle_info(battle_id),
         true <-
           (last_battle_time >= battle_start_time and
              last_battle_time < battle_start_time + @expired) || {:error, :battle_expired} do
      Dc.Manager.send_to_ds(battle_id, ~M{%Pbm.Dsa.QuitGame2C battle_id, player_id: role_id})
      :ok
    else
      {:error, :battle_expired} ->
        Logger.debug("battle was expired.battle_id: #{battle_id}")
        %Pbm.Battle.ExitBattle2C{} |> sd()
        {:ok, ~M{state|battle_id: 0,last_battle_time: nil}}

      _ ->
        Logger.debug("battle not exist.battle_id: #{battle_id}")
        %Pbm.Battle.ExitBattle2C{} |> sd()
        {:ok, ~M{state|battle_id: 0,last_battle_time: nil}}
    end
  end
end
