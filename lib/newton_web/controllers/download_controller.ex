defmodule NewtonWeb.DownloadController do
  use NewtonWeb, :controller
  require Logger

  def download(%Plug.Conn{} = conn, _params) do
    base = Application.fetch_env!(:newton, :exam_folder_base)
    path = Path.join(base, conn.query_params["path"])
    Logger.info("Rendering download #{path}")
    send_download(conn, {:file, path}, filename: Path.basename(path))
  end
end
