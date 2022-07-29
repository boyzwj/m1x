defmodule M1xWeb.PageController do
  use M1xWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def get_pbclass(conn, _params) do
    cs_data =
      Tool.Pbid.proto_ids("#{:code.priv_dir(:m1x)}/dc_proto/")
      |> PBClass.content()

    conn
    |> put_resp_content_type("text/cs")
    |> put_resp_header("content-disposition", "attachment; filename=\"Pb.cs\"")
    |> put_root_layout(false)
    |> send_resp(200, cs_data)
  end

  def get_log(conn, params) do
    filename = params["f"]
    log_dir = Application.get_env(:logger, :error_log)[:path] |> Path.dirname()

    conn
    |> put_resp_content_type("text/MD")
    |> put_resp_header("content-disposition", "attachment; filename=\"#{filename}\"")
    |> send_file(200, "#{log_dir}/#{filename}")
  end
end
