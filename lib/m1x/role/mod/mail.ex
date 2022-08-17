defmodule Role.Mod.Mail do
  defstruct role_id: nil, mail_ids: [], last_gmail_id: 0, last_mail_id: 0
  use Role.Mod
  @fetch_interval 3

  # 从个人邮箱拉去个人邮件
  # 通知新邮件给客户端
  def on_receive_new_mail(~M{%M role_id,last_mail_id,mail_ids} = state, _) do
    with undeal_mails when undeal_mails != [] <- Mail.Personal.fetch_all_mails(role_id),
         {last_mail_id, mail_ids, new_brief_mails} <-
           Mail.add_mails(role_id, undeal_mails, last_mail_id, mail_ids, nil) do
      ~M{state|last_mail_id,mail_ids} |> set_data()
      Mail.Personal.clear_mails(role_id)
      IO.inspect(mail_ids, label: "on_receive_new_mail")
      broadcast_mails(new_brief_mails)
    end
  end

  # 从全服邮箱拉取全服邮件
  # 从个人邮箱拉去个人邮件
  defp on_init(~M{%M role_id,last_mail_id,mail_ids,last_gmail_id} = state) do
    ~M{%Role.Mod.Role create_time} = Role.Mod.Role.get_data()

    Mail.init_brief_mails(role_id, mail_ids)

    with global_mails <- Mail.Global.fetch_mails(last_gmail_id),
         personal_mails <- Mail.Personal.fetch_all_mails(role_id),
         undeal_mails <-
           (global_mails ++ personal_mails) |> Enum.sort_by(&(create_time > &1.create_time)),
         {last_mail_id, mail_ids, _new_brief_mails} <-
           Mail.add_mails(role_id, undeal_mails, last_mail_id, mail_ids, create_time) do
      Mail.Personal.clear_mails(role_id)

      IO.inspect(mail_ids, label: "on_init")

      with ~M{%Mail id: last_gmail_id} <- List.last(global_mails) do
        ~M{state|last_mail_id,mail_ids,last_gmail_id}
      else
        _ ->
          ~M{state|last_mail_id,mail_ids}
      end
    else
      _ ->
        state
    end
  end

  def secondloop(~M{%M role_id,last_mail_id,mail_ids,last_gmail_id} = state, now) do
    with true <- rem(now, @fetch_interval) == rem(role_id, @fetch_interval),
         global_mails when global_mails != [] <- Mail.Global.fetch_mails(last_gmail_id),
         {last_mail_id, mail_ids, new_brief_mails} <-
           Mail.add_mails(role_id, global_mails, last_mail_id, mail_ids, nil),
         ~M{%Mail id: last_gmail_id} <- List.last(global_mails) do
      ~M{state|last_mail_id,mail_ids,last_gmail_id} |> set_data()
      IO.inspect(mail_ids, label: "secondloop")
      broadcast_mails(new_brief_mails)
    end
  end

  def h(~M{%M }, ~M{%Pbm.Mail.Info2S}) do
    mails =
      for ~M{id,cfg_id,status,body} <- Mail.get_brief_mails() do
        ~M{%Pbm.Mail.BriefMail2C id,cfg_id,status,body}
      end

    ~M{%Pbm.Mail.Info2C mails} |> sd()
    :ok
  end

  def h(~M{%M role_id}, ~M{%Pbm.Mail.Mail2S id}) do
    with ~M{%Mail id,cfg_id,body,args,attachs,create_time,expire_time,status} <-
           Mail.get(role_id, id) do
      ~M{%Pbm.Mail.Mail2C id,cfg_id,body,args,attachs,create_time,expire_time,status} |> sd()
    else
      nil ->
        throw("mail no found! id: #{id}")
    end

    :ok
  end

  defp broadcast_mails(brief_mails) do
    for {_, ~M{id,cfg_id,status,body}} <- brief_mails do
      ~M{%Pbm.Mail.BriefMail2C id,cfg_id,status,body} |> sd()
      Logger.debug(~M{%Pbm.Mail.BriefMail2C id,cfg_id,status,body})
    end
  end
end
