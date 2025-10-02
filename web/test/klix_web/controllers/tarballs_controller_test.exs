defmodule KlixWeb.TarballsControllerTest do
  use KlixWeb.ConnCase, async: true

  import Klix.AccountsFixtures

  @tag :tmp_dir
  test "sends the current flake config as a tarball", %{
    conn: conn,
    tmp_dir: dir
  } do
    {:ok, image} =
      user_fixture()
      |> Klix.Accounts.Scope.for_user()
      |> Klix.Images.create(Klix.Factory.params(:image))

    datetime = DateTime.utc_now() |> DateTime.to_iso8601()
    message = "#{image.uri_id}#{datetime}"

    {signature, 0} =
      System.shell("""
      ssh-keygen -q -f "#{dir}/mykey" -N ""
      echo -n #{message} | ssh-keygen -q -Y sign -n file -f "#{dir}/mykey"
      """)

    conn =
      get(
        conn,
        ~p"/images/#{image.uri_id}/#{Base.encode64(datetime)}/#{Base.encode64(signature)}/config.tar.gz"
      )

    assert response(conn, :ok)
    body = conn.resp_body

    :ok = :erl_tar.extract({:binary, body}, [{:cwd, dir}, :compressed])

    files = File.ls!(dir)
    assert "flake.lock" in files
    assert "flake.nix" in files
  end

  test "404s when signature doesn't verify", %{conn: conn} do
    conn = get(conn, ~p"/images/not-a-uuid/not-a-datetime/not-a-sig/config.tar.gz")
    assert response(conn, :not_found)
  end
end
