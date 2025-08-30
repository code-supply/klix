defmodule KlixWeb.CustomImageTest do
  use KlixWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  @valid_params %{
    "hostname" => "my-printer",
    "public_key" =>
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINxmQDDdlqsMmQ69TsBWxqFOPfyipAX0h+4GGELsGRup nobody@ever"
  }

  test "shows a message when download requested", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    {:ok, _view, html} =
      view
      |> form("#image", image: @valid_params)
      |> render_submit()
      |> follow_redirect(conn)

    assert html =~ "being prepared"
  end

  test "shows validation errors", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    assert view |> form("#image", image: %{hostname: "-"}) |> render_submit() =~
             "must not start with a hyphen"
  end

  test "has a download button", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    assert view |> has_element?("#download")
  end
end
