defmodule KlixWeb.TarballsControllerTest do
  use KlixWeb.ConnCase, async: true

  import Klix.AccountsFixtures

  setup %{conn: conn} do
    user = user_fixture()
    scope = Klix.Accounts.Scope.for_user(user)
    %{conn: log_in_user(conn, user), scope: scope}
  end

  @tag :tmp_dir
  test "sends the current flake config as a tarball", %{
    conn: conn,
    scope: scope,
    tmp_dir: tmp_dir
  } do
    {:ok, image} =
      Klix.Images.create(
        scope,
        Klix.Factory.params(:image,
          klipper_config: [
            type: :github,
            owner: "code-supply",
            repo: "code-supply",
            path: "boxes/ketchup-king/klipper"
          ]
        )
      )

    conn = get(conn, ~p"/images/#{image.id}/config.tar.gz")
    assert response(conn, :ok)
    body = conn.resp_body

    :ok = :erl_tar.extract({:binary, body}, [{:cwd, tmp_dir}, :compressed])

    assert File.ls!(tmp_dir) == ~w(flake.lock flake.nix)
  end
end
