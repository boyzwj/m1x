defmodule Dba.Redis.Api do
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
    Redis.get("account:#{token}")
  end

  def set_account_info(token, role_id) do
    Redis.set("account:#{token}", role_id)
  end

  def make_role_id() do
    block_id = FastGlobal.get(:block_id, 1)
    block_id * 100_000_000 + Redis.incr("role_id:#{block_id}")
  end

  def make_battle_id() do
    Redis.incr("battle_id")
  end

  def clearall() do
    Redis.clearall()
  end
end
