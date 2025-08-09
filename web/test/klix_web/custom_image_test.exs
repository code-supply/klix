defmodule KlixWeb.CustomImageTest do
  use KlixWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "has a download button", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    assert view |> has_element?("#download")
  end
end
