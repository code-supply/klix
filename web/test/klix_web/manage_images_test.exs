defmodule KlixWeb.ManageImagesTest do
  use KlixWeb.ConnCase, async: true

  setup %{conn: conn} do
    user = user_fixture()
    scope = Klix.Accounts.Scope.for_user(user)
    %{conn: log_in_user(conn, user), scope: scope}
  end

  test "shows a list of plugins that're enabled", %{conn: conn, scope: scope} do
    {:ok, image} =
      Images.create(
        scope,
        Klix.Factory.params(:image,
          plugin_kamp_enabled: true,
          plugin_shaketune_enabled: false,
          plugin_z_calibration_enabled: true
        )
      )

    {:ok, view, _html} = live(conn, ~p"/images/#{image.id}")

    assert view |> has_element?("#plugins li", "KAMP")
    refute view |> has_element?("#plugins li", "Shaketune")
    assert view |> has_element?("#plugins li", "Z Calibration")
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

  @tag :tmp_dir
  test "shows download links, but only for completed builds", %{
    conn: conn,
    scope: scope,
    tmp_dir: dir
  } do
    {:ok, %{builds: [build]} = image} =
      Images.create(scope, Klix.Factory.params(:image, hostname: "machineA"))

    write_image(dir)
    {:ok, build} = Images.file_ready(build, dir)
    {:ok, _build} = Images.build_completed(build)

    {:ok, view, _html} = live(conn, ~p"/images/#{image.id}")

    assert view |> has_element?("#builds a[download]", ~r/.+ GB/),
           element(view, "#builds a[download]") |> render
  end

  @tag :tmp_dir
  test "when a build completes, show download link", %{
    conn: conn,
    scope: scope,
    tmp_dir: dir
  } do
    {:ok, %{builds: [build]} = image} =
      Images.create(scope, Klix.Factory.params(:image, hostname: "machineA"))

    {:ok, view, _html} = live(conn, ~p"/images/#{image.id}")

    write_image(dir)
    {:ok, build} = Images.file_ready(build, dir)
    {:ok, _build} = Images.build_completed(build)

    assert view |> has_element?("#builds a[download]", ~r/.+ GB/),
           element(view, "#builds a[download]") |> render
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

    assert view |> has_element?("#builds li")
  end
end
