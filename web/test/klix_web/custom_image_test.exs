defmodule KlixWeb.CustomImageTest do
  use KlixWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

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
