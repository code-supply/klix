defmodule KlixWeb.ImageController do
  use KlixWeb, :controller

  def download(conn, %{"build_id" => build_id, "image_id" => image_id}) do
    case Klix.Images.find_build(image_id, build_id) do
      nil ->
        conn
        |> send_resp(:not_found, "")

      build ->
        sd_dir = Path.join(build.output_path, "sd-image")
        {:ok, [sd_file]} = File.ls(sd_dir)
        send_file(conn, :ok, Path.join(sd_dir, sd_file))
    end
  end
end
