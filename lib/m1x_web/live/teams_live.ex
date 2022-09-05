defmodule M1xWeb.TeamsLive do
  use M1xWeb, :live_view
  use Common
  alias Phoenix.LiveView.Socket

  def mount(_params, _session, socket) do
    if connected?(socket) do
      :timer.send_interval(2000, self(), :tick)
    end

    socket =
      socket
      |> assign_team_infos()
      |> assign(:online_roles, [])
      |> assign(:active_modal, false)

    {:ok, socket}
  end

  def handle_event("kick", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("active_modal", ~m{teamid,leaderid}, socket) do
    socket
    |> assign(:active_modal, true)
    |> assign(:cur_team_id, String.to_integer(teamid))
    |> assign(:cur_leader_id, String.to_integer(leaderid))
    |> assign_role_infos()
    |> then(&{:noreply, &1})
  end

  def handle_event("close_modal", _p, %Socket{} = socket) do
    socket
    |> assign(:active_modal, false)
    |> then(&{:noreply, &1})
  end

  def handle_event("invite_roles", ~m{invite_roles}, %Socket{assigns: assigns} = socket) do
    with ~m{role_id} <- invite_roles,
         ~M{cur_team_id,cur_leader_id} <- assigns,
         role_id <- String.to_integer(role_id),
         {:ok, _} <- invite_into_team(cur_team_id, role_id, cur_leader_id) do
      socket
      |> assign(:active_modal, false)
      |> then(&{:noreply, &1})
    else
      {:error, msg} when is_binary(msg) ->
        put_flash(socket, :error, msg)
        |> then(&{:noreply, &1})

      params ->
        Logger.warn("unkonw params: #{inspect(params)}")
        socket
    end
  end

  def handle_info(:tick, socket) do
    socket =
      socket
      |> assign_team_infos()

    {:noreply, socket}
  end

  defp assign_team_infos(socket) do
    team_infos = get_team_infos()

    socket
    |> assign(:team_infos, team_infos)
  end

  defp assign_role_infos(socket) do
    online_roles =
      Role.Mod.Friend.get_friend_ids()
      |> Enum.map(fn role_id ->
        role_name =
          Role.Svr.get_data(role_id, Role.Mod.Role)
          |> Map.get(:role_name)

        {role_name, role_id}
      end)

    socket
    |> assign(:online_roles, online_roles)
  end

  def get_team_infos() do
    for {_team_id, team_pid} <- Team.Manager.list_teams() do
      :sys.get_state(team_pid)
    end
  end

  @statuses %{0 => "idle", 1 => "matching", 2 => "matched", 3 => "battle"}
  defp humanize_team_status(status) do
    "#{status}(#{@statuses[status]})"
  end

  defp invite_into_team(team_id, role_id, invitor_id) do
    reply = 1

    try do
      Role.Svr.get_data(role_id, Role.Mod.Team)
      |> Role.Mod.Team.h(~M{%Pbm.Team.InviteReply2S team_id,reply,invitor_id})
    catch
      msg ->
        {:error, msg}
    end
  end
end
