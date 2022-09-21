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

  def set_rank_info(key, sortedset, indexs) do
    Api.set_rank_info(key, sortedset, indexs)
  end

  def get_rank_info(key) do
    Api.get_rank_info(key)
  end

  def set_mail(role_id, mail_id, mail) do
    Api.set_mail(role_id, mail_id, mail)
  end

  def get_mail(role_id, mail_id) do
    Api.get_mail(role_id, mail_id)
  end

  def load_global_mails(options) do
    Api.load_global_mails(options)
  end

  def save_global_mail(mail) do
    Api.save_global_mail(mail)
  end

  def load_personal_mails(role_id) do
    Api.load_personal_mails(role_id)
  end

  def add_personal_mail(role_id, mail) do
    Api.add_personal_mail(role_id, mail)
  end

  def clear_personal_mails(role_id) do
    Api.clear_personal_mails(role_id)
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
