defmodule Mail.Personal do
  use Common

  def db_key(role_id) do
    "#{__MODULE__}:#{role_id}"
  end

  # 发送个人系统邮件
  def send_mail(role_ids, cfg_id, args, expire_time) do
    # TODO need set body,attachs and expire_time
    mail = ~M{%Mail cfg_id,args,expire_time}
    IO.inspect(mail, label: "send_mail")
    do_send_mail(role_ids, mail)
  end

  # 发送个人自定义邮件
  def send_mail(role_ids, body, args, attachs, expire_time) do
    mail = ~M{%Mail body,args,attachs,expire_time}
    do_send_mail(role_ids, mail)
  end

  # 获取信箱所有邮件 asc
  @spec fetch_all_mails(neg_integer()) :: [%Mail{}]
  def fetch_all_mails(role_id) do
    db_key(role_id)
    |> Redis.lrange(0, -1)
    |> Enum.map(&Poison.decode!(&1, as: %Mail{}))
  end

  # 清除信箱
  def clear_mails(role_id) do
    db_key(role_id) |> Redis.del()
  end

  defp do_send_mail(role_id, mail) when is_integer(role_id), do: do_send_mail([role_id], mail)

  defp do_send_mail(role_ids, ~M{%Mail expire_time} = mail) do
    expire_time = expire_time || %Mail{}.expire_time
    mail = ~M{mail|create_time: Util.unixtime(),expire_time}
    Enum.each(role_ids, &save_mail(&1, mail))
    Role.Svr.manifold_do_callback_fun(role_ids, &Role.Mod.Mail.on_receive_new_mail/2)
  end

  defp save_mail(role_id, %Mail{} = mail) do
    content = Map.from_struct(mail)
    db_key(role_id) |> Redis.rpush(content)
  end
end
