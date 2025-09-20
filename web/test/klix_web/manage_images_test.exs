defmodule KlixWeb.ManageImagesTest do
  use KlixWeb.ConnCase, async: true

  setup %{conn: conn} do
    user = user_fixture()
    scope = Klix.Accounts.Scope.for_user(user)
    %{conn: log_in_user(conn, user), scope: scope}
  end

  test "shows an updating duration", %{conn: conn, scope: scope} do
    {:ok, image} =
      Images.create(scope, Klix.Factory.params(:image, hostname: "machineA"))

    {:ok, view, _html} = live(conn, ~p"/images/#{image.id}")

    initial_duration = view |> element(".duration") |> render()

    send(view.pid, {:tick, DateTime.utc_now() |> DateTime.add(3, :second)})

    new_duration = view |> element(".duration") |> render()

    # lexical comparison should be sufficient here
    assert new_duration > initial_duration
  end

  test "shows download links, but only for completed builds", %{conn: conn, scope: scope} do
    {:ok, %{builds: [build]} = image} =
      Images.create(scope, Klix.Factory.params(:image, hostname: "machineA"))

    {:ok, _build} = Images.build_completed(build)

    {:ok, view, _html} = live(conn, ~p"/images/#{image.id}")

    assert view |> has_element?("#builds a[download]")
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

    {:ok, view, _html} =
      view |> element("a", "Details") |> render_click() |> follow_redirect(conn)

    assert view |> has_element?("*", "being prepared"), view |> render()
  end

  test "shows builds", %{conn: conn, scope: scope} do
    {:ok, %{builds: [build]} = image} =
      Images.create(scope, Klix.Factory.params(:image, hostname: "machineA"))

    {:ok, _} = Images.build_completed(build)

    {:ok, view, _html} = live(conn, ~p"/images/#{image.id}")

    assert view |> has_element?("table#builds tbody tr")
  end
end
