defmodule Mail do
  use Common

  defstruct id: nil,
            cfg_id: 0,
            body: "",
            args: [],
            attachs: [],
            create_time: 0,
            expire_time: 253_402_300_799,
            status: 0

  @brief_mail_body_length 5

  def db_key(role_id, mail_id) do
    "mails:#{role_id}:#{mail_id}"
  end

  def add_mails([], _last_mail_id, _mails_ids, _create_time) do
    {:error, "no need deal mails"}
  end

  def add_mails(role_id, undeal_mails, old_last_mail_id, mail_ids, create_time) do
    with {last_mail_id, mail_ids, new_mails} <-
           calc_new_mails(undeal_mails, old_last_mail_id, mail_ids, create_time),
         true <- last_mail_id > old_last_mail_id || {:error, "nothing change"},
         :ok <- save_mails(new_mails, role_id),
         {:ok, new_brief_mails} <- update_brief_mails(new_mails) do
      {last_mail_id, mail_ids, new_brief_mails}
    else
      error ->
        error
    end
  end

  # undeal_mails order_by asc, new_mails order_by desc
  defp calc_new_mails(undeal_mails, last_mail_id, mail_ids, role_create_time) do
    {new_last_mail_id, new_mails_ids, new_mails} =
      undeal_mails
      |> Enum.reduce(
        {last_mail_id, mail_ids, []},
        fn ~M{%Mail create_time} = x, {i, mails_ids_acc, mails_acc} ->
          if role_create_time == nil or create_time > role_create_time do
            id = i + 1
            {id, [id | mails_ids_acc], [~M{x|id} | mails_acc]}
          else
            {i, mails_ids_acc, mails_acc}
          end
        end
      )

    {new_last_mail_id, new_mails_ids, new_mails}
  end

  defp update_brief_mails(new_mails) do
    new_brief_mails =
      for ~M{%Mail id,status,cfg_id,body} <- new_mails, into: %{} do
        body = String.split_at(body, @brief_mail_body_length) |> elem(0)
        {id, ~M{%Pbm.Mail.BriefMail2C id,cfg_id,body,status}}
      end

    get_brief_mails()
    |> Map.merge(new_brief_mails)
    |> set_brief_mails()

    {:ok, new_brief_mails}
  end

  defp set_brief_mails(brief_mails) do
    Process.put({Role.Mod.Mail, :brief_mails}, brief_mails)
  end

  def get_brief_mails() do
    Process.get({Role.Mod.Mail, :brief_mails}, %{})
  end

  def init_brief_mails(role_id, mail_ids) do
    for mail_id <- mail_ids, into: %{} do
      ~M{%Mail id,cfg_id,body,status} = get(role_id, mail_id)
      {mail_id, ~M{%Pbm.Mail.BriefMail2C id,cfg_id,body,status}}
    end
    |> set_brief_mails()
  end

  defp save_mails(mails, role_id) do
    Enum.each(mails, &save(&1, role_id))
  end

  def save(~M{%Mail id} = mail, role_id) do
    value = Map.from_struct(mail) |> Poison.encode!()
    db_key(role_id, id) |> Redis.set(value)
  end

  def get(role_id, mail_id) do
    value =
      db_key(role_id, mail_id)
      |> Redis.get()

    if is_nil(value) do
      nil
    else
      value |> Poison.decode!(as: %Mail{})
    end
  end

  def set(role_id, mail_id, value) do
    db_key(role_id, mail_id) |> Redis.set(value)
  end
end
