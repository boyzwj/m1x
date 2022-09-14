defmodule Authorize do
  use Common
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
      throw("登录token长度太短")
    end

    if String.length(token) > @max_len do
      throw("登录token长度太长")
    end

    data = Dba.get_account_info(token)

    if data do
      Jason.decode(data)
    else
      role_id = Dba.make_role_id()
      Dba.set_account_info(token, role_id)
      create_time = Util.unixtime()

      Dba.save_role_data(%Role.Mod.Role{
        role_id: role_id,
        account: token,
        role_name: token,
        create_time: create_time
      })

      {:ok, role_id}
    end
  end
end
