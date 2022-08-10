defmodule Role.Mod.Mail do
  defstruct role_id: nil, mails: []
  use Role.Mod
  alias Mail.Schema

  @fetch_interval 3

  defp on_init(~M{%M mails} = state) do
    ~M{%Role.Mod.Role create_time} = Role.Mod.Role.get_data()

    with true <- mails != [],
         ~M{%Schema id: last_mail_id} <- hd(mails),
         undeal_mails <- Mail.fetch_mails(last_mail_id),
         true <- undeal_mails != [] or {:last_mail_id, last_mail_id},
         mails <- add_undeal_mails(undeal_mails, mails, create_time) do
      ~M{state|mails}
    else
      {:last_mail_id, last_mail_id} ->
        set_last_mail_id(last_mail_id)
        state

      _ ->
        set_last_mail_id(0)
        state
    end
  end

  def secondloop(~M{%M role_id,mails} = state, now) do
    with true <- rem(now, @fetch_interval) == rem(role_id, @fetch_interval),
         undeal_mails when undeal_mails != [] <- Mail.fetch_mails(get_last_mail_id()),
         mails <- add_undeal_mails(undeal_mails, mails, nil),
         state <- ~M{state|mails} do
      set_data(state)
      broadcast_mails(undeal_mails)
      state
    else
      _ ->
        state
    end
  end

  defp add_undeal_mails(undeal_mails, mails, role_create_time) do
    mails =
      undeal_mails
      |> Enum.reduce(mails, fn x, acc ->
        if role_create_time == nil or x.create_time > role_create_time do
          [x | acc]
        else
          acc
        end
      end)

    ~M{%Schema id: last_mail_id} = hd(mails)
    set_last_mail_id(last_mail_id)
    mails
  end

  def h(~M{%M mails}, ~M{%Pbm.Mail.Info2S}) do
    mails =
      for ~M{%Schema id,oid,args,body,attachs,create_time,expire_time,status} <- mails do
        ~M{%Pbm.Mail.Mail2C id,oid,args,body,attachs,create_time,expire_time,status}
      end

    ~M{%Pbm.Mail.Info2C mails} |> sd()
    :ok
  end

  defp broadcast_mails([]), do: :ok

  defp broadcast_mails([mail | mails]) do
    ~M{%Schema id,body,attachs,create_time,expire_time,status} = mail
    ~M{%Pbm.Mail.Mail2C id,body,attachs,create_time,expire_time,status} |> sd()
    broadcast_mails(mails)
  end

  defp get_last_mail_id() do
    Process.get({__MODULE__, :last_mail_id})
  end

  defp set_last_mail_id(last_mail_id) do
    Process.put({__MODULE__, :last_mail_id}, last_mail_id)
  end
end
