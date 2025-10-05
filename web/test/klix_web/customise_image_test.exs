defmodule KlixWeb.CustomiseImageTest do
  use KlixWeb.ConnCase, async: true

  import Klix.AccountsFixtures
  import Phoenix.LiveViewTest

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

  test "shows a message when download requested", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/images/new")

    {:ok, _view, html} =
      view
      |> form("#image", image: Klix.Factory.params(:image))
      |> render_submit()
      |> follow_redirect(conn)

    assert html =~ "being prepared"
  end

  test "images that are already built are downloadable", %{conn: conn, scope: scope} do
    {:ok, %{builds: [build]} = image} = Klix.Images.create(scope, Klix.Factory.params(:image))
    {:ok, _build} = Klix.Images.build_completed(build)

    {:ok, view, _html} = live(conn, ~p"/images/#{image.id}")

    assert view |> has_element?("[download]")
  end

  @tag :tmp_dir
  test "shows download link when image is built", %{scope: scope, conn: conn, tmp_dir: tmp_dir} do
    {:ok, view, _html} = live(conn, ~p"/images/new")

    {:error, {:live_redirect, %{kind: :push, to: <<"/images/", image_id::binary>>}}} =
      response =
      view
      |> form("#image", image: Klix.Factory.params(:image))
      |> render_submit()

    {:ok, view, _html} =
      follow_redirect(response, conn)

    %{builds: [build]} = Klix.Images.find!(scope, image_id)

    top_dir = write_image(tmp_dir, "the image contents")

    Klix.Images.set_build_output_path(build, top_dir)
    Klix.Images.build_completed(build)

    expected_host = Application.fetch_env!(:ex_aws, :s3)[:host]
    assert view |> has_element?("[download][href*='https://#{expected_host}']")
  end

  test "shows validation errors", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/images/new")

    assert view |> form("#image", image: %{hostname: "-"}) |> render_submit() =~
             "must not start with a hyphen"
  end

  test "has a submit button", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/images/new")

    assert view |> has_element?("#download")
  end
end
