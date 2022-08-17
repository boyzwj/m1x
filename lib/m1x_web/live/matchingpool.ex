defmodule M1xWeb.Matchingpool do
  use M1xWeb, :live_view
  use Common

  def mount(_params, _session, socket) do
    if connected?(socket) do
      :timer.send_interval(2000, self(), :tick)
    end

    {:ok, socket}
  end

  def handle_info(:tick, socket) do
    Logger.debug("fuckoff")
    {:noreply, socket}
  end

  def assign_pool_infos(socket) do
    pool_infos =
      for mode <- Data.GameModeManage.ids(), into: %{} do
        {mode, Team.Matcher.Svr.get_pool_infos(mode, [])}
      end

    socket |> assign(:pool_infos, pool_infos)
  end
end
