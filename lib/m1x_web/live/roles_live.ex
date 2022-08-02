defmodule M1xWeb.RolesLive do
  use M1xWeb, :live_view
  use Common

  def mount(_params, _session, socket) do
    if connected?(socket) do
      :timer.send_interval(2000, self(), :tick)
    end

    socket =
      socket
      |> assign_player_infos()

    {:ok, socket}
  end

  def handle_event("kick", params, socket) do
    IO.inspect({:kick, params})
    {:noreply, socket}
  end

  def handle_info(:tick, socket) do
    socket =
      socket
      |> assign_player_infos()

    {:noreply, socket}
  end

  defp assign_player_infos(socket) do
    player_infos =
      for pid <- :pg.get_members(Role.Svr) do
        Role.Svr.get_data(pid, Role.Mod.Role)
        |> Map.from_struct()
        |> Map.put(:pid, "#{inspect(pid)}")
      end

    socket |> assign(:player_infos, player_infos)
  end
end
