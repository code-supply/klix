defmodule KlixWeb.BuildsController do
  use KlixWeb, :controller

  alias Klix.Images

  def download(conn, %{"image_id" => image_id, "id" => build_id}) do
    scope = conn.assigns.current_scope
    build = Images.find_build!(scope, image_id, build_id)

    redirect(conn, external: Images.download_url(build))
  end
end
