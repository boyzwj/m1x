defmodule M1xWeb.MailLive do
  use M1xWeb, :live_view

  defmodule SendMail do
    use Ecto.Schema
    import Ecto.Changeset

    schema "send_mail" do
      field :role_id, :integer
      field :cfg_id, :integer, default: 0
      field :body, :string, default: ""
      field :args, {:array, :integer}
      field :attachs, {:array, :integer}, virtual: true
    end

    def changeset(struct, params) do
      struct
      |> cast(params, [:role_id, :cfg_id, :body, :args])
      |> validate_number(:role_id, greater_than: 0)
      |> validate_number(:cfg_id, greater_than: 0)
    end
  end

  @impl true
  def mount(_params, _session, socket) do
    changeset = SendMail.changeset(%SendMail{}, %{})
    mail_type = Map.get(socket.assigns, :mail_type, "2")
    {:ok, assign(socket, changeset: changeset, mail_type: mail_type)}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  # The modal component emits this event when `PetalComponents.Modal.hide_modal()` is called.
  # This happens when the user clicks the dark background or the 'X'.
  @impl true
  def handle_event("close_modal", _, socket) do
    # Go back to the :index live action
    {:noreply, push_redirect(socket, to: "/")}
  end

  def handle_event("validate", %{"send_mail" => params}, socket) do
    changeset =
      %SendMail{}
      |> SendMail.changeset(params)
      |> Map.put(:action, :insert)

    socket = assign(socket, changeset: changeset, mail_type: params["mail_type"])

    {:noreply, socket}
  end

  def handle_event("send_mail", %{"send_mail" => %{"mail_type" => "1"} = params}, socket) do
    role_id = String.to_integer(params["role_id"])
    cfg_id = String.to_integer(params["cfg_id"])
    args = parse_args(params["args"])
    Mail.Personal.send_mail([role_id], cfg_id, args, nil)
    {:noreply, push_redirect(socket, to: "/")}
  end

  def handle_event("send_mail", %{"send_mail" => %{"mail_type" => "2"} = params}, socket) do
    role_id = String.to_integer(params["role_id"])
    attachs = parse_attachs(params["attachs"])
    args = parse_args(params["args"])
    Mail.Personal.send_mail([role_id], params["body"], args, attachs, nil)
    {:noreply, push_redirect(socket, to: "/")}
  end

  def handle_event("send_mail", %{"send_mail" => %{"mail_type" => "3"} = params}, socket) do
    cfg_id = String.to_integer(params["cfg_id"])
    args = parse_args(params["args"])
    Mail.Global.send_mail(cfg_id, args, nil)
    {:noreply, push_redirect(socket, to: "/")}
  end

  def handle_event("send_mail", %{"send_mail" => %{"mail_type" => "4"} = params}, socket) do
    attachs = parse_attachs(params["attachs"])
    args = parse_args(params["args"])
    Mail.Global.send_mail(params["body"], args, attachs, nil)
    {:noreply, push_redirect(socket, to: "/")}
  end

  defp parse_attachs(""), do: []

  defp parse_attachs(attachs_str) do
    attachs_str
    |> String.split("\n")
    |> Enum.map(fn x ->
      String.split(x, ",") |> Enum.map(&String.to_integer/1)
    end)
  end

  defp parse_args(""), do: []

  defp parse_args(args_str) do
    args_str
    |> String.split(",")
    |> Enum.map(&String.trim/1)
  end
end
