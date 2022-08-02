defmodule M1xWeb.GameDashboard do
  use M1xWeb, :live_view
  use Common

  def mount(_params, _session, socket) do
    if connected?(socket) do
      :timer.send_interval(2000, self(), :tick)
    end

    socket =
      socket
      |> assign_log_files()
      |> assign_online_num()

    {:ok, socket}
  end

  def handle_event("restart", _params, socket) do
    socket =
      socket
      |> put_flash(:info, "Restarting")

    :init.restart()
    {:noreply, socket}
  end

  def handle_event("cleardb", _params, socket) do
    Redis.clearall()
    :init.restart()

    socket =
      socket
      |> put_flash(:info, "Database cleared !! Restarting...")

    {:noreply, socket}
  end

  def handle_event("clearlog", _params, socket) do
    logdir =
      Application.get_env(:logger, :error_log)[:path]
      |> Path.dirname()

    for filename <- File.ls!(logdir) do
      File.rm!("#{logdir}/#{filename}")
    end

    :init.restart()

    socket =
      socket
      |> put_flash(:info, "Logfile cleared !! Restarting...")

    {:noreply, socket}
  end

  def handle_info(:tick, socket) do
    socket =
      socket
      |> assign_log_files()
      |> assign_online_num()

    {:noreply, socket}
  end

  defp assign_log_files(socket) do
    log_files =
      Application.get_env(:logger, :error_log)[:path]
      |> Path.dirname()
      |> File.ls!()
      |> Enum.filter(&String.ends_with?(&1, ".MD"))
      |> Enum.sort()

    socket
    |> assign(:log_files, log_files)
  end

  defp assign_online_num(socket) do
    socket |> assign(:online_num, length(:pg.get_members(Role.Svr)))
  end
end
