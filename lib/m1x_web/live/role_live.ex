defmodule M1xWeb.RoleLive do
  use M1xWeb, :live_view
  use Common

  def update_role(changes) do
    Role.Mod.Role.get_data() |> Map.merge(changes) |> Role.Mod.Role.set_data()
    :ok
  end

  def mount(%{"role_id" => role_id}, _session, socket) do
    socket =
      socket
      |> assign(:role_id, String.to_integer(role_id))
      |> assign_role_info(%{})

    {:ok, socket}
  end

  def handle_event("kick", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("update_role", ~m{role}, socket) do
    with %Phoenix.LiveView.Socket{assigns: %{changeset: changeset, role_id: role_id}} <- socket,
         %Ecto.Changeset{valid?: true, changes: changes} when map_size(changes) > 0 <-
           Role.Mod.Role.changeset(changeset.data, role) |> Map.put(:action, :update),
         :ok <- Role.Svr.call(role_id, {:apply, __MODULE__, :update_role, [changes]}) do
      assign_role_info(socket, changes)
      |> put_flash(:info, "保存成功")
      |> then(&{:noreply, &1})
    else
      _ ->
        socket
        |> then(&{:noreply, &1})
    end
  end

  defp assign_role_info(socket, params) do
    data =
      socket.assigns.role_id
      |> Role.Svr.get_data(Role.Mod.Role)
      |> Role.Mod.Role.changeset(params)

    assign(socket, :changeset, data)
  end
end
