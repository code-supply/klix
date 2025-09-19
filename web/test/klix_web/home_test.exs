defmodule KlixWeb.HomeTest do
  use KlixWeb.ConnCase, async: true

  import Klix.AccountsFixtures
  import Phoenix.LiveViewTest

  test "shows intro when not logged in", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/")

    assert html =~ "Spend time printing"
  end

  test "shows link to start customising when logged in", %{conn: conn} do
    conn = log_in_user(conn, user_fixture())

    {:ok, view, _html} = live(conn, ~p"/")

    {:ok, view, _html} = view |> element("#begin") |> render_click() |> follow_redirect(conn)

    assert view |> has_element?("*", "Build your image")
  end
end
