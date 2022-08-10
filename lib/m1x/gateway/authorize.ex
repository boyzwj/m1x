defmodule Authorize do
  @min_len 4
  @max_len 32

  def authorize(token) do
    try do
      do_authorize(token)
    catch
      error ->
        {:error, error}
    end
  end

  def do_authorize(token) do
    if String.length(token) < @min_len do
      throw("token长度太短")
    end

    if String.length(token) > @max_len do
      throw("token长度太长")
    end

    data = Redis.get("account:#{token}")

    if data do
      Jason.decode(data)
    else
      role_id = GID.get_role_id()
      Redis.set("account:#{token}", role_id)
      dbkey = Role.Misc.dbkey(role_id)
      create_time = Util.unixtime()

      Redis.hset(dbkey, Role.Mod.Role, %{
        role_id: role_id,
        account: token,
        role_name: token,
        create_time: create_time
      })

      {:ok, role_id}
    end
  end
end
