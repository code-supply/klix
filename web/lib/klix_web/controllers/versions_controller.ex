defmodule KlixWeb.VersionsController do
  use KlixWeb, :controller

  def update(conn, params) do
    case conn.assigns.current_scope do
      nil ->
        send_resp(conn, :not_found, "Not Found")

      scope ->
        {:ok, _image} = Klix.Images.store_versions(scope, params)
        send_resp(conn, :ok, "")
    end
  end
end
