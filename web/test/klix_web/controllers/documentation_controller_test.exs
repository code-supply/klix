defmodule KlixWeb.DocumentationControllerTest do
  use KlixWeb.ConnCase, async: true

  test "missing pages 404", %{conn: conn} do
    conn = get(conn, ~p"/docs/missing-page")
    assert html_response(conn, :not_found)
  end
end
