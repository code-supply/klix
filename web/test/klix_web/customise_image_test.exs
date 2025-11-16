defmodule KlixWeb.CustomiseImageTest do
  use KlixWeb.ConnCase, async: true

  import Klix.AccountsFixtures
  import Phoenix.LiveViewTest

  setup %{conn: conn} do
    user = user_fixture()
    scope = Klix.Accounts.Scope.for_user(user)
    %{conn: log_in_user(conn, user), scope: scope}
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

    Klix.Images.file_ready(build, top_dir)
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
