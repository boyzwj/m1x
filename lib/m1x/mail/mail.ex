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
  @per_num 2
  @status_unread 0
  @status_read_no_take 1
  @status_finished 2
  @undeal_status [@status_unread, @status_read_no_take]

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
         {:ok, new_brief_mails} <- update_brief_mails(new_mails),
         :ok <- update_pagination(mail_ids) do
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

  def get_brief_mail(mail_id) do
    get_brief_mails() |> Map.get(mail_id)
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
    Dba.set_mail(role_id, id, mail)
  end

  def get(role_id, mail_id) do
    Dba.get_mail(role_id, mail_id)
  end

  def update_pagination(mail_ids) do
    Enum.chunk_every(mail_ids, @per_num)
    |> then(&Process.put({Role.Mod.Mail, :pagination}, &1))

    :ok
  end

  def get_per_num() do
    @per_num
  end

  def get_undeal_num() do
    get_brief_mails() |> Enum.filter(&(elem(&1, 1).status in @undeal_status)) |> length()
  end

  def list_brief_mails(cur_page) do
    mails = get_brief_mails()

    Process.get({Role.Mod.Mail, :pagination}, [])
    |> Enum.at(cur_page, [])
    |> Enum.map(&Map.get(mails, &1))
  end

  def calc_mail_status(%Mail{status: status}, :read)
      when status in [@status_finished, @status_read_no_take],
      do: {:error, :aready_read}

  def calc_mail_status(%Mail{status: @status_unread, attachs: []}, :read),
    do: {:ok, @status_finished}

  def calc_mail_status(%Mail{status: @status_unread, attachs: [_ | _]}, :read),
    do: {:ok, @status_read_no_take}

  def calc_mail_status(%Mail{status: @status_finished}, :take), do: {:error, :aready_took}
  def calc_mail_status(%Mail{attachs: []}, :take), do: {:error, :attach_empty}

  def calc_mail_status(%Mail{status: @status_read_no_take, attachs: [_ | _]}, :take),
    do: {:ok, @status_finished}

  def calc_mail_status(%Mail{status: @status_unread, attachs: [_ | _]}, :take),
    do: {:ok, @status_finished}

  def calc_mail_status(mail, action),
    do: {:unknow_status, mail, action}

  def update_mail(~M{%Mail id} = mail, role_id) do
    with "OK" <- save(mail, role_id),
         %Pbm.Mail.BriefMail2C{} = brief_mail <- get_brief_mail(id) do
      get_brief_mails()
      |> Map.put(id, brief_mail)
      |> set_brief_mails()

      {:ok, brief_mail}
    else
      error ->
        {:error, error}
    end
  end
end
