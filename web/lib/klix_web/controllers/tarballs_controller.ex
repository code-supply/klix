defmodule KlixWeb.TarballsController do
  use KlixWeb, :controller

  def download(conn, %{"image_id" => image_id}) do
    image = Klix.Images.find!(image_id)
    {:ok, _snapshot, tarball} = Klix.Images.snapshot(image)
    send_resp(conn, :ok, tarball)
  end
end
