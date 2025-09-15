defmodule KlixWeb.CustomiseImageTest do
  use KlixWeb.ConnCase, async: true

  import Klix.AccountsFixtures
  import Phoenix.LiveViewTest

  setup %{conn: conn} do
    %{conn: log_in_user(conn, user_fixture())}
  end

  test "shows a message when download requested", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    {:ok, _view, html} =
      view
      |> form("#image", image: Klix.Factory.params(:image))
      |> render_submit()
      |> follow_redirect(conn)

    assert html =~ "being prepared"
  end

  test "images that are already built are downloadable", %{conn: conn} do
    {:ok, %{builds: [build]} = image} = Klix.Factory.params(:image) |> Klix.Images.create()
    {:ok, _build} = Klix.Images.build_completed(build)

    {:ok, view, _html} = live(conn, ~p"/images/#{image.id}")

    assert view |> has_element?("#download")
  end

  @tag :tmp_dir
  test "shows download link when image is built", %{conn: conn, tmp_dir: tmp_dir} do
    {:ok, view, _html} = live(conn, ~p"/")

    {:error, {:live_redirect, %{kind: :push, to: <<"/images/", image_id::binary>>}}} =
      response =
      view
      |> form("#image", image: Klix.Factory.params(:image))
      |> render_submit()

    {:ok, view, _html} =
      follow_redirect(response, conn)

    %{builds: [build]} = Klix.Images.find!(image_id)

    top_dir = write_image(tmp_dir, "the image contents")

    Klix.Images.set_build_output_path(build, top_dir)
    Klix.Images.build_completed(build)

    link_selector =
      "#download[download][href='#{~p"/images/#{image_id}/builds/#{build.id}/klix.img.zst'"}]"

    {:ok, conn} =
      view
      |> element(link_selector)
      |> render_click()
      |> follow_redirect(conn)

    assert response(conn, :ok)
  end

  test "shows validation errors", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    assert view |> form("#image", image: %{hostname: "-"}) |> render_submit() =~
             "must not start with a hyphen"
  end

  test "has a submit button", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    assert view |> has_element?("#download")
  end
end
