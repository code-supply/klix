defmodule KlixWeb.BuildNewImageTest do
  use KlixWeb.ConnCase, async: true

  import Klix.AccountsFixtures
  import Phoenix.LiveViewTest

  setup %{conn: conn} do
    user = user_fixture()
    scope = Klix.Accounts.Scope.for_user(user)
    %{conn: log_in_user(conn, user), scope: scope}
  end

  test "shows a message when all steps are complete", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/images/new")

    view
    |> fill_in(machine: "raspberry_pi_5")
    |> render_submit()

    view
    |> fill_in(hostname: "my-machine", timezone: "Europe/London")
    |> render_submit()

    view
    |> fill_in(public_key: Factory.params(:image).public_key)
    |> render_submit()

    view
    |> fill_in(plugin_kamp_enabled: false)
    |> render_submit()

    {:ok, _view, html} =
      view
      |> fill_in(
        klipper_config: [
          type: "github",
          owner: "code-supply",
          repo: "code-supply",
          path: "some/path"
        ]
      )
      |> render_submit()
      |> follow_redirect(conn)

    assert html =~ "being prepared"
  end

  test "errors are shown and prevent progress", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/images/new")

    assert view
           |> fill_in(machine: "")
           |> render_submit() =~ ~r/can.*t be blank/
  end

  test "going back renders the form with previously-filled values", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/images/new")

    view
    |> fill_in(machine: "raspberry_pi_5")
    |> render_submit()

    view |> go_back()

    assert view |> has_element?("#image_machine option[value=raspberry_pi_5][selected]"),
           "Expected Raspberry Pi 5 to be selected in:\n#{view |> element("#image_machine") |> render()}"
  end

  defp fill_in(view, params) do
    view |> form("#step", image: params)
  end

  defp go_back(view) do
    view |> element("#prev") |> render_click()
  end
end
