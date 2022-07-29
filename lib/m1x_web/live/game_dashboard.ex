defmodule M1xWeb.GameDashboard do
  use M1xWeb, :live_view
  use Common

  def mount(_params, _session, socket) do
    if connected?(socket) do
      :timer.send_interval(2000, self(), :tick)
    end

    online_num = :pg.get_members(Role.Svr) |> length()

    player_infos =
      for pid <- :pg.get_members(Role.Svr) do
        Role.Svr.get_data(pid, Role.Mod.Role)
      end

    socket =
      socket
      |> assign(:online_num, online_num)
      |> assign(:player_infos, player_infos)
      |> assign_log_files()

    {:ok, socket}
  end

  def handle_event("on", _params, socket) do
    socket = assign(socket, :online_num, 100)
    {:noreply, socket}
  end

  def handle_event("off", _params, socket) do
    online_num = :pg.get_members(Role.Svr) |> length()
    socket = assign(socket, :online_num, online_num)
    {:noreply, socket}
  end

  def handle_info(:tick, socket) do
    online_num = :pg.get_members(Role.Svr) |> length()

    player_infos =
      for pid <- :pg.get_members(Role.Svr) do
        Role.Svr.get_data(pid, Role.Mod.Role)
      end

    socket =
      socket
      |> assign(:online_num, online_num)
      |> assign(:player_infos, player_infos)
      |> assign_log_files()

    {:noreply, socket}
  end

  defp assign_log_files(socket) do
    log_files =
      Application.get_env(:logger, :error_log)[:path]
      |> Path.dirname()
      |> File.ls!()
      |> Enum.sort()

    socket
    |> assign(:log_files, log_files)
  end
end
