defmodule Dba.Mnesia.Api do
  def save_role_data(data) do
    tab = data.__struct__
    key = data.role_id
    data = Map.from_struct(data) |> Map.delete(:__meta__) |> Poison.encode!()
    record = {tab, key, data, Util.unixtime()}
    :mnesia.dirty_write(tab, record)
  end

  def load_role_data(tab, key) do
    case :mnesia.dirty_read(tab, key) do
      [{_tab, _key, data, _timestamp}] -> data
      _ -> nil
    end
  end

  def set_session_info(session_id, role_id) do
    %Mnesia.Service.Session{id: session_id, role_id: role_id}
    |> dirty_write()
  end

  def get_session_info(session_id) do
    with %Mnesia.Service.Session{role_id: role_id} <-
           dirty_read(Mnesia.Service.Session, session_id) do
      role_id
    else
      _ ->
        nil
    end
  end

  def set_account_info(token, role_id) do
    %Mnesia.Storage.Account{token: token, role_id: role_id}
    |> dirty_write()
  end

  def get_account_info(token) do
    with %Mnesia.Storage.Account{role_id: role_id} <- dirty_read(Mnesia.Storage.Account, token) do
      role_id
    else
      _ ->
        nil
    end
  end

  def make_role_id() do
    block_id = FastGlobal.get(:block_id, 1)
    block_id * 100_000_000 + dirty_update_counter(Mnesia.Storage.Global, :role_id)
  end

  def make_battle_id() do
    dirty_update_counter(Mnesia.Storage.Global, :battle_id)
  end

  @spec dirty_read(any, any) :: nil | struct
  def dirty_read(tab, key) do
    case :mnesia.dirty_read(tab, key) do
      [t] -> Memento.Query.Data.load(t)
      [] -> nil
    end
  end

  def read(tab, key) do
    Memento.transaction!(fn -> Memento.Query.read(tab, key) end)
  end

  def dirty_write(data) do
    data
    |> Memento.Query.Data.dump()
    |> :mnesia.dirty_write()
  end

  def write(data) do
    Memento.transaction!(fn -> Memento.Query.write(data) end)
  end

  def dirty_delete(tab, key) do
    :mnesia.dirty_delete(tab, key)
  end

  def delete(tab, key) do
    Memento.transaction!(fn -> Memento.Query.delete(tab, key) end)
  end

  def dirty_update_counter(tab, key, incr \\ 1) do
    with :ok <- :mnesia.dirty_update_counter(tab, key, incr) do
      :mnesia.dirty_write({tab, key, 1})
      1
    else
      value ->
        value
    end
  end

  def update_counter(tab, key, name, incr \\ 1) do
    Memento.transaction!(fn ->
      Memento.Query.read(tab, key)
      |> Map.update!(name, &(&1 + incr))
      |> Memento.Query.write()
    end)
  end

  def is_key(tab, key) do
    :ets.member(tab, key)
  end

  def clear_table(tab) do
    :mnesia.clear_table(tab)
  end

  def clearall() do
    for {mod, _, _} <- Dba.Mnesia.Def.role_tables() do
      clear_table(mod)
    end

    for {mod, _} <- Dba.Mnesia.Def.tables() do
      clear_table(mod)
    end

    :ok
  end
end
