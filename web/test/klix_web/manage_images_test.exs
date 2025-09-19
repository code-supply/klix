defmodule KlixWeb.ManageImagesTest do
  use KlixWeb.ConnCase, async: true

  setup %{conn: conn} do
    user = user_fixture()
    scope = Klix.Accounts.Scope.for_user(user)
    %{conn: log_in_user(conn, user), scope: scope}
  end

  test "lists all of the user's images", %{conn: conn, scope: scope} do
    {:ok, _image} = Images.create(scope, Klix.Factory.params(:image, hostname: "machineA"))
    {:ok, _image} = Images.create(scope, Klix.Factory.params(:image, hostname: "machineB"))
    {:ok, _image} = Images.create(scope, Klix.Factory.params(:image, hostname: "machineC"))

    {:ok, view, _html} = live(conn, ~p"/images")

    assert view |> has_element?("#images li", "machineA")
    assert view |> has_element?("#images li", "machineB")
    assert view |> has_element?("#images li", "machineC")
  end

  test "can click through to an image's page", %{conn: conn, scope: scope} do
    {:ok, _image} = Images.create(scope, Klix.Factory.params(:image, hostname: "machineA"))
    {:ok, view, _html} = live(conn, ~p"/images")
    view |> element("a", "Details") |> render_click()

    assert view |> has_element?("*", "being prepared"), view |> render()
  end
end
