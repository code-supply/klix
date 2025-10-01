defmodule KlixWeb.TarballsController do
  use KlixWeb, :controller

  def download(conn, _params) do
    {:ok, _snapshot, tarball} = Klix.Images.snapshot(conn.assigns.current_scope.image)
    send_resp(conn, :ok, tarball)
  end
end
