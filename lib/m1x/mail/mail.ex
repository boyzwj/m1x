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
    fields = %Pbm.Mail.BriefMail2C{} |> Map.from_struct() |> Map.delete(:__uf__) |> Map.keys()

    for mail_id <- mail_ids, into: %{} do
      brief_mail =
        mget(role_id, mail_id, fields)
        |> then(&struct(Pbm.Mail.BriefMail2C, &1))

      {mail_id, brief_mail}
    end
    |> set_brief_mails()
  end

  defp save_mails(mails, role_id) do
    Enum.each(mails, &save(&1, role_id))
  end

  def save(~M{%Mail id} = mail, role_id) do
    array = encode(mail)
    db_key(role_id, id) |> Redis.hset_array(array)
  end

  def get(role_id, mail_id) do
    db_key(role_id, mail_id)
    |> Redis.hgetall()
    |> decode()
  end

  def get(role_id, mail_id, field) do
    db_key(role_id, mail_id)
    |> Redis.hget(field)
    |> then(&parse_field_type([field, &1]))
    |> elem(1)
  end

  def set(role_id, mail_id, field, value) do
    db_key(role_id, mail_id) |> Redis.hset(field, value)
  end

  def mget(role_id, mail_id, fields) do
    db_key(role_id, mail_id)
    |> Redis.hmget(fields)
    |> Enum.zip_with(fields, &[&2, &1])
    |> Enum.map(&parse_field_type/1)
    |> Enum.into(%{})
  end

  defp encode(~M{%Mail args,attachs} = mail) do
    args = Poison.encode!(args)
    attachs = Poison.encode!(attachs)

    ~M{mail|args,attachs}
    |> Map.from_struct()
    |> Enum.flat_map(fn {k, v} -> [k, v] end)
  end

  defp decode(array) do
    array
    |> Enum.chunk_every(2)
    |> parse_fields(%{})
    |> then(&struct(Mail, &1))
  end

  defp parse_fields([], result), do: result

  defp parse_fields([h | rest], result) do
    {k, v} = parse_field_type(h)
    parse_fields(rest, Map.put(result, k, v))
  end

  defp parse_field_type([key, value]) when is_atom(key), do: parse_field_type(["#{key}", value])
  defp parse_field_type(["id", value]), do: {:id, String.to_integer(value)}
  defp parse_field_type(["cfg_id", value]), do: {:cfg_id, String.to_integer(value)}
  defp parse_field_type(["body", value]), do: {:body, value}
  defp parse_field_type(["args", value]), do: {:args, Poison.decode!(value)}
  defp parse_field_type(["attachs", value]), do: {:attachs, Poison.decode!(value)}
  defp parse_field_type(["create_time", value]), do: {:create_time, String.to_integer(value)}
  defp parse_field_type(["expire_time", value]), do: {:expire_time, String.to_integer(value)}
  defp parse_field_type(["status", value]), do: {:status, String.to_integer(value)}
end
