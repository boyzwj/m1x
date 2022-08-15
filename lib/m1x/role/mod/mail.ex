defmodule Role.Mod.Mail do
  defstruct role_id: nil, mails: [], last_gmail_id: 0
  use Role.Mod
  @fetch_interval 3

  # 从个人邮箱拉去个人邮件
  # 通知新邮件给客户端
  def on_receive_new_mail(~M{%M mails,role_id} = state, _) do
    IO.inspect("on_receive_new_mail")

    with new_mails <- Mail.Personal.fetch_all_mails(role_id),
         {added_num, mails} <- add_undeal_mails(new_mails, mails, nil),
         state <- ~M{state|mails} |> set_data() do
      Mail.Personal.clear_mails(role_id)

      mails
      |> Enum.slice(0, added_num)
      |> Enum.reverse()
      |> broadcast_mails()

      state
    end
  end

  defp on_before_save(~M{%M mails} = state) do
    mails = Enum.map(mails, &Map.from_struct/1)
    ~M{state|mails}
  end

  # 从全服邮箱拉取全服邮件
  # 从个人邮箱拉去个人邮件
  defp on_init(~M{%M mails,role_id,last_gmail_id} = state) do
    ~M{%Role.Mod.Role create_time} = Role.Mod.Role.get_data()
    mails = Enum.map(mails, &Poison.decode!(&1, as: %Mail{}))

    with global_mails <- Mail.Global.fetch_mails(last_gmail_id),
         personal_mails <- Mail.Personal.fetch_all_mails(role_id),
         IO.inspect(global_mails, label: "global_mails"),
         IO.inspect(personal_mails, label: "personal_mails"),
         undeal_mails <-
           (global_mails ++ personal_mails) |> Enum.sort_by(&(create_time > &1.create_time)),
         {_added_num, mails} <- add_undeal_mails(undeal_mails, mails, create_time) do
      Mail.Personal.clear_mails(role_id)

      IO.inspect(mails, label: "on_init")

      if global_mails != [] do
        last_gmail_id = List.last(global_mails).id
        ~M{state|mails,last_gmail_id}
      else
        ~M{state|mails}
      end
    else
      _ ->
        state
    end
  end

  # def secondloop(state, now) do
  #   Process.sleep(300)
  #   state
  # end

  def secondloop(~M{%M role_id,mails,last_gmail_id} = state, now) do
    with true <- rem(now, @fetch_interval) == rem(role_id, @fetch_interval),
         global_mails when global_mails != [] <- Mail.Global.fetch_mails(last_gmail_id),
         {added_num, mails} <- add_undeal_mails(global_mails, mails, nil),
         last_gmail_id <- List.last(global_mails).id,
         state <- ~M{state|mails,last_gmail_id} do
      set_data(state)

      mails
      |> Enum.slice(0, added_num)
      |> Enum.reverse()
      |> broadcast_mails()

      IO.inspect(mails, label: "secondloop")
      state
    else
      _ ->
        state
    end
  end

  # undeal_mails order_by asc, mails order_by desc
  defp add_undeal_mails(undeal_mails, mails, role_create_time) do
    %Mail{id: last_mail_id} = List.first(mails, %Mail{id: 0})

    {new_last_mail_id, mails} =
      undeal_mails
      |> Enum.reduce({last_mail_id, mails}, fn ~M{%Mail create_time} = x, {i, mails_acc} ->
        if role_create_time == nil or create_time > role_create_time do
          id = i + 1
          {id, [~M{x|id} | mails_acc]}
        else
          {i, mails_acc}
        end
      end)

    {new_last_mail_id - last_mail_id, mails}
  end

  def h(~M{%M mails}, ~M{%Pbm.Mail.Info2S}) do
    mails =
      for ~M{%Mail id,cfg_id,args,body,attachs,create_time,expire_time,status} <- mails do
        ~M{%Pbm.Mail.Mail2C id,cfg_id,args,body,attachs,create_time,expire_time,status}
      end

    ~M{%Pbm.Mail.Info2C mails} |> sd()
    :ok
  end

  defp broadcast_mails([]), do: :ok

  defp broadcast_mails([mail | mails]) do
    ~M{%Mail id,cfg_id,body,attachs,create_time,expire_time,status} = mail
    ~M{%Pbm.Mail.Mail2C id,cfg_id,body,attachs,create_time,expire_time,status} |> sd()
    Logger.debug(~M{%Pbm.Mail.Mail2C id,cfg_id,body,attachs,create_time,expire_time,status})
    broadcast_mails(mails)
  end
end
