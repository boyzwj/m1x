defmodule Dba.Mnesia.Api do
  import ShorterMaps

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

  def set_rank_info(key, sortedset, indexs) do
    ~M{%Mnesia.Storage.Rank key, set: sortedset, indexs}
    |> dirty_write()
  end

  def get_rank_info(key) do
    with ~M{%Mnesia.Storage.Rank set,indexs} <- dirty_read(Mnesia.Storage.Rank, key) do
      ~M{set,indexs}
    else
      _ ->
        nil
    end
  end

  def set_mail(role_id, mail_id, ~M{%Mail } = mail) do
    key = "#{role_id}:#{mail_id}"

    ~M{%Mnesia.Storage.Mail key, role_id, mail}
    |> dirty_write()
  end

  def get_mail(role_id, mail_id) do
    key = "#{role_id}:#{mail_id}"

    with ~M{%Mnesia.Storage.Mail mail} <- dirty_read(Mnesia.Storage.Mail, key) do
      mail
    else
      _ ->
        nil
    end
  end

  def load_global_mails([{:limit, limit} | _]) do
    max_id =
      case Memento.transaction!(fn -> :mnesia.last(Mnesia.Storage.GlobalMail) end) do
        :"$end_of_table" ->
          0

        id ->
          id
      end

    range = min(0, max_id - limit)

    Memento.transaction!(fn ->
      Memento.Query.select(Mnesia.Storage.GlobalMail, {:>, :id, range})
      |> Enum.map(& &1.mail)
    end)
  end

  def save_global_mail(%Mail{id: id} = mail) do
    ~M{%Mnesia.Storage.GlobalMail id, mail}
    |> dirty_write()
  end

  def load_personal_mails(role_id) do
    with ~M{%Mnesia.Storage.PersonalMail mails} <-
           dirty_read(Mnesia.Storage.PersonalMail, role_id) do
      mails
    else
      _ ->
        []
    end
  end

  def add_personal_mail(role_id, %Mail{} = mail) do
    mails = load_personal_mails(role_id)

    ~M{%Mnesia.Storage.PersonalMail role_id, mails:  [mail | mails]}
    |> dirty_write()
  end

  def clear_personal_mails(role_id) do
    key = "Mail.Personal:#{role_id}"
    Redis.del(key)
  end

  def make_role_id() do
    block_id = Node.Misc.block_id()
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
