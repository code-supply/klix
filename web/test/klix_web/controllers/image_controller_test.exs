defmodule KlixWeb.ImageControllerTest do
  use KlixWeb.ConnCase, async: true

  import Klix.AccountsFixtures

  setup %{conn: conn} do
    user = user_fixture()
    scope = Klix.AccountsFixtures.user_fixture() |> Klix.Accounts.Scope.for_user()
    %{conn: log_in_user(conn, user), scope: scope}
  end

  @tag :tmp_dir
  test "sends the SD image from inside the build's output path", %{
    conn: conn,
    scope: scope,
    tmp_dir: tmp_dir
  } do
    {:ok, %{builds: [build]} = image} = Klix.Images.create(scope, Klix.Factory.params(:image))

    top_dir = write_image(tmp_dir, "an image")

    {:ok, _build} = Klix.Images.set_build_output_path(build, top_dir)

    assert get(conn, ~p"/images/#{image.id}/builds/#{build.id}/klix.img.zst").resp_body ==
             "an image"
  end

  test "404s if there's no matching image and build", %{conn: conn} do
    assert conn
           |> get(~p"/images/1/builds/1/klix.img.zst")
           |> response(:not_found)
  end
end
