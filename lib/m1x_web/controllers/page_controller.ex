defmodule M1xWeb.PageController do
  use M1xWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
