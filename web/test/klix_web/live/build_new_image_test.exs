defmodule KlixWeb.BuildNewImageTest do
  use KlixWeb.ConnCase, async: true

  import Klix.AccountsFixtures
  import Phoenix.LiveViewTest

  describe "when not logged in" do
    test "can still create an anonymous image", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/images/new")

      assert html =~ "not logged in"
      refute view |> has_element?(".text-error"), "found error on page: #{view |> render()}"

      view
      |> fill_in(machine: "raspberry_pi_5")
      |> render_submit()

      path = assert_patch view
      assert path =~ "step=LocaleAndIdentity"

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
  end

  describe "when logged in" do
    setup %{conn: conn} do
      user = user_fixture()
      scope = Klix.Accounts.Scope.for_user(user)
      %{conn: log_in_user(conn, user), scope: scope}
    end

    test "shows a message when all steps are complete", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/images/new")

      refute html =~ "not logged in"
      refute view |> has_element?(".text-error"), "found error on page: #{view |> render()}"

      view
      |> fill_in(machine: "raspberry_pi_5")
      |> render_submit()

      path = assert_patch view
      assert path =~ "step=LocaleAndIdentity"

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

    test "can return to a step and continue with the wizard", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/images/new")

      view
      |> fill_in(machine: "raspberry_pi_5")
      |> render_submit()

      {:ok, view, _html} = live(conn, ~p"/images/new?step=LocaleAndIdentity")

      view
      |> fill_in(hostname: "my-machine", timezone: "Europe/London")
      |> render_submit()

      view
      |> fill_in(public_key: Factory.params(:image).public_key)
      |> render_submit()

      {:ok, view, _html} = live(conn, ~p"/images/new?step=Authentication")

      assert view |> fill_in(public_key: "a new key") |> render_submit()
    end

    test "can return to the start of the wizard with previous data preloaded", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/images/new")

      view
      |> fill_in(machine: "raspberry_pi_5")
      |> render_submit()

      {:ok, view, _html} = live(conn, ~p"/images/new")

      assert view
             |> fill_in(hostname: "my-machine", timezone: "Europe/London")
             |> render_submit()
    end

    test "errors are shown and prevent progress", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/images/new")

      assert view
             |> fill_in(machine: "")
             |> render_submit() =~ ~r/can.*t be blank/
    end
  end

  defp fill_in(view, params) do
    view |> form("#step", image: params)
  end
end
