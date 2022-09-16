defmodule Dba do
  alias Dba.Mnesia.Api

  def save_role_data(data) do
    Api.save_role_data(data)
  end

  def load_role_data(tab, key) do
    Api.load_role_data(tab, key)
  end

  def get_session_info(session_id) do
    Api.get_session_info(session_id)
  end

  def set_session_info(session_id, role_id) do
    Api.set_session_info(session_id, role_id)
  end

  def get_account_info(token) do
    Api.get_account_info(token)
  end

  def set_account_info(token, role_id) do
    Api.set_account_info(token, role_id)
  end

  def make_role_id() do
    Api.make_role_id()
  end

  def make_battle_id() do
    Api.make_battle_id()
  end

  def clearall() do
    Api.clearall()
  end
end
