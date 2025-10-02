defmodule KlixWeb.TarballsController do
  use KlixWeb, :controller

  def download(conn, _params) do
    case conn.assigns.current_scope do
      nil ->
        send_resp(conn, :not_found, "Not Found")

      scope ->
        {:ok, _snapshot, tarball} = Klix.Images.snapshot(scope.image)
        send_resp(conn, :ok, tarball)
    end
  end
end
