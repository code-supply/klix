defmodule KlixWeb.BuildsControllerTest do
  use KlixWeb.ConnCase, async: true

  describe "when not logged in" do
    test "can download ownerless images", %{conn: conn} do
      {:ok, image} = Images.create(Scope.for_user(nil), Klix.Factory.params(:image))
      [build] = image.builds
      conn = get(conn, ~p"/images/#{image.id}/builds/#{build.id}")
      assert html_response(conn, 302)
      assert Enum.into(conn.resp_headers, %{})["location"] == Images.download_url(build)
    end

    test "cannot download owned images", %{conn: conn} do
      user = user_fixture()
      {:ok, image} = Images.create(Scope.for_user(user), Klix.Factory.params(:image))
      [build] = image.builds

      assert_raise Ecto.NoResultsError, fn ->
        get(conn, ~p"/images/#{image.id}/builds/#{build.id}")
      end
    end
  end

  describe "when logged in" do
    setup :register_and_log_in_user

    test "can download own images", %{conn: conn, user: user} do
      {:ok, image} = Images.create(Scope.for_user(user), Klix.Factory.params(:image))
      [build] = image.builds
      conn = get(conn, ~p"/images/#{image.id}/builds/#{build.id}")
      assert html_response(conn, 302)
      assert Enum.into(conn.resp_headers, %{})["location"] == Images.download_url(build)
    end

    test "cannot download others' images", %{conn: conn} do
      user = user_fixture()
      {:ok, image} = Images.create(Scope.for_user(user), Klix.Factory.params(:image))
      [build] = image.builds

      assert_raise Ecto.NoResultsError, fn ->
        get(conn, ~p"/images/#{image.id}/builds/#{build.id}")
      end
    end
  end
end
