defmodule Dba.Redis.Api do
  import ShorterMaps

  defp dbkey(role_id) do
    "role:#{role_id}"
  end

  def save_role_data(data) do
    tab = data.__struct__
    key = dbkey(data.role_id)
    data = Map.from_struct(data) |> Map.delete(:__meta__)
    Redis.hset(key, tab, data)
  end

  def load_role_data(tab, key) do
    key = dbkey(key)
    Redis.hget(key, tab)
  end

  def get_session_info(session_id) do
    Redis.get("session:#{session_id}")
  end

  def set_session_info(session_id, role_id) do
    Redis.set("session:#{session_id}", role_id)
  end

  def get_account_info(token) do
    if res = Redis.get("account:#{token}") do
      String.to_integer(res)
    else
      nil
    end
  end

  def set_account_info(token, role_id) do
    Redis.set("account:#{token}", role_id)
  end

  def set_rank_info(key, sortedset, indexs) do
    set = sortedset |> Enum.map(&Tuple.to_list/1)

    Poison.encode!(%{set: set, indexs: indexs})
    |> then(&Redis.set(key, &1))
  end

  def get_rank_info(key) do
    with data when not is_nil(data) <- Redis.get(key),
         {:ok, ~m{set,indexs}} <- Poison.decode(data) do
      set = set |> Enum.map(&List.to_tuple/1)
      ~M{set,indexs}
    else
      _ ->
        nil
    end
  end

  def set_mail(role_id, mail_id, ~M{%Mail } = mail) do
    key = "mails:#{role_id}:#{mail_id}"
    value = Map.from_struct(mail) |> Poison.encode!()
    Redis.set(key, value)
  end

  def get_mail(role_id, mail_id) do
    key = "mails:#{role_id}:#{mail_id}"

    with data when not is_nil(data) <- Redis.get(key),
         {:ok, mail} <- Poison.decode(data, as: %Mail{}) do
      mail
    else
      _ ->
        nil
    end
  end

  def load_global_mails([{:limit, limit} | _]) do
    Redis.lrange(Mail.Global, -limit, -1)
    |> Enum.reduce([], fn x, acc -> [Poison.decode!(x, as: %Mail{}) | acc] end)
  end

  def save_global_mail(%Mail{} = mail) do
    Redis.rpush(Mail.Global, Map.from_struct(mail))
  end

  def load_personal_mails(role_id) do
    key = "Mail.Personal:#{role_id}"

    Redis.lrange(key, 0, -1)
    |> Enum.map(&Poison.decode!(&1, as: %Mail{}))
  end

  def add_personal_mail(role_id, %Mail{} = mail) do
    key = "Mail.Personal:#{role_id}"
    Redis.rpush(key, Map.from_struct(mail))
  end

  def clear_personal_mails(role_id) do
    key = "Mail.Personal:#{role_id}"
    Redis.del(key)
  end

  def make_role_id() do
    block_id = Node.Misc.block_id()
    block_id * 100_000_000 + Redis.incr("role_id:#{block_id}")
  end

  def make_battle_id() do
    Redis.incr("battle_id")
  end

  def clearall() do
    Redis.clearall()
  end
end
