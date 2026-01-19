defmodule KlixWeb.ManageImagesTest do
  use KlixWeb.ConnCase, async: true

  test "cannot see soft-delete option when not logged in", %{conn: conn} do
    {:ok, image} = Images.create(Scope.for_user(nil), Klix.Factory.params(:image))
    {:ok, view, _html} = live(conn, ~p"/images/#{image.id}")
    refute view |> has_element?("#delete")
  end

  describe "when logged in" do
    setup %{conn: conn} do
      user = user_fixture()
      scope = Klix.Accounts.Scope.for_user(user)
      %{conn: log_in_user(conn, user), scope: scope}
    end

    test "can't go to another user's image", %{conn: conn} do
      different_user = user_fixture()
      different_scope = Klix.Accounts.Scope.for_user(different_user)

      {:ok, image} = Klix.Images.create(different_scope, Klix.Factory.params(:image))

      assert_raise Ecto.NoResultsError, fn ->
        live(conn, ~p"/images/#{image.id}")
      end
    end

    test "can soft-delete an image", %{conn: conn, scope: scope} do
      {:ok, image} = Images.create(scope, Klix.Factory.params(:image))
      {:ok, view, _html} = live(conn, ~p"/images/#{image.id}")
      {:ok, view, _html} = view |> element("#delete") |> render_click() |> follow_redirect(conn)

      assert view |> has_element?("h1", "Your Images")
      refute view |> has_element?("#images li")
      assert view |> has_element?("*", "deleted")
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

    test "duration updates don't interrupt installation accordion", %{conn: conn, scope: scope} do
      {:ok, image} = Images.create(scope, Klix.Factory.params(:image, hostname: "machineA"))
      {:ok, view, _html} = live(conn, ~p"/images/#{image.id}")

      for id <- ~w(sd-gui sd-cli wifi) do
        refute view |> has_element?("##{id}[checked]")
        view |> element("##{id}") |> render_click()
        assert view |> has_element?("##{id}[checked]")
      end
    end

    @tag :tmp_dir
    test "shows most recent software versions on the printer", %{
      conn: conn,
      scope: scope,
      tmp_dir: dir
    } do
      {:ok, %{builds: [build]} = image} = Images.create(scope, Klix.Factory.params(:image))

      write_image(dir)
      {:ok, build} = Images.file_ready(build, dir)
      {:ok, build} = Images.store_versions(build, %{"klipper" => "3.0.0"})
      {:ok, image} = Images.store_versions(Scope.for_image(image), %{"klipper" => "4.0.0"})
      {:ok, _build} = Images.build_completed(build)

      {:ok, view, _html} = live(conn, ~p"/images/#{image.id}")

      assert view |> has_element?(".printer .versions .klipper", "4.0.0")
      assert view |> has_element?(".printer .klix-updated", ~r/\d{4}-\d{2}-\d{2}/)
    end

    @tag :tmp_dir
    test "shows versions of software for completed builds", %{
      conn: conn,
      scope: scope,
      tmp_dir: dir
    } do
      {:ok, %{builds: [build]} = image} = Images.create(scope, Klix.Factory.params(:image))

      write_image(dir)
      {:ok, build} = Images.file_ready(build, dir)
      {:ok, build} = Images.store_versions(build, %{"klipper" => "3.2.1"})
      {:ok, _build} = Images.build_completed(build)

      {:ok, view, _html} = live(conn, ~p"/images/#{image.id}")

      assert view |> has_element?(".build .versions .klipper", "3.2.1")
    end

    @tag :tmp_dir
    test "shows download links for already-completed builds", %{
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

    test "lists all of the user's images, except incomplete ones", %{conn: conn, scope: scope} do
      {:ok, _user} =
        Images.save_unfinished(
          scope,
          Klix.Factory.params(:image, hostname: "incomplete")
        )

      {:ok, _image} = Images.create(scope, Klix.Factory.params(:image, hostname: "machineA"))
      {:ok, _image} = Images.create(scope, Klix.Factory.params(:image, hostname: "machineB"))
      {:ok, _image} = Images.create(scope, Klix.Factory.params(:image, hostname: "machineC"))

      {:ok, view, _html} = live(conn, ~p"/images")

      assert view |> has_element?("#images li", "machineA")
      assert view |> has_element?("#images li", "machineB")
      assert view |> has_element?("#images li", "machineC")
      refute view |> has_element?("#images li", "incomplete")
    end

    test "can click through to an image's page", %{conn: conn, scope: scope} do
      {:ok, _image} = Images.create(scope, Klix.Factory.params(:image, hostname: "machineA"))
      {:ok, view, _html} = live(conn, ~p"/images")

      {:ok, view, _html} =
        view |> element("a", "Details") |> render_click() |> follow_redirect(conn)

      assert view |> has_element?("*", "being prepared"), view |> render()
      refute view |> has_element?(".printer .versions")
      assert view |> has_element?(".printer .klix-updated", "never")
    end

    test "shows builds", %{conn: conn, scope: scope} do
      {:ok, %{builds: [build]} = image} =
        Images.create(scope, Klix.Factory.params(:image, hostname: "machineA"))

      {:ok, _} = Images.build_completed(build)

      {:ok, view, _html} = live(conn, ~p"/images/#{image.id}")

      assert view |> has_element?("#builds li")
    end
  end
end
