defmodule KlixWeb.ImageControllerTest do
  use KlixWeb.ConnCase, async: true

  @tag :tmp_dir
  test "sends the SD image from inside the build's output path", %{conn: conn, tmp_dir: tmp_dir} do
    {:ok, %{builds: [build]} = image} = Klix.Factory.params(:image) |> Klix.Images.create()

    top_dir = write_image(tmp_dir, "an image")

    {:ok, _build} = Klix.Images.set_build_output_path(build, top_dir)

    assert get(conn, ~p"/images/#{image.id}/builds/#{build.id}/content").resp_body == "an image"
  end

  test "404s if there's no matching image and build", %{conn: conn} do
    assert conn
           |> get(~p"/images/1/builds/1/content")
           |> response(:not_found)
  end
end
