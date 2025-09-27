defmodule KlixWeb.TarballsController do
  use KlixWeb, :controller

  def download(conn, %{"uuid" => uuid}) do
    image = Klix.Images.find!(uuid)
    {:ok, _snapshot, tarball} = Klix.Images.snapshot(image)
    send_resp(conn, :ok, tarball)
  end
end
