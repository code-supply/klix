defmodule KlixWeb.ImageController do
  use KlixWeb, :controller

  def download(conn, %{"build_id" => build_id, "image_id" => image_id}) do
    case Klix.Images.find_build(conn.assigns.current_scope, image_id, build_id) do
      nil ->
        send_resp(conn, :not_found, "")

      build ->
        send_file(conn, :ok, Klix.Images.sd_file_path(build))
    end
  end
end
