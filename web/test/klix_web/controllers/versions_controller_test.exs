defmodule KlixWeb.VersionsControllerTest do
  use KlixWeb.ConnCase, async: true

  import Klix.AccountsFixtures

  @tag :tmp_dir
  test "accepts version numbers from signed requests", %{
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
      conn
      |> put_req_header("content-type", "application/json")
      |> put(
        ~p"/images/#{image.uri_id}/#{Base.encode64(datetime)}/#{Base.encode64(signature)}/versions",
        %{
          "cage" => "0.2.0",
          "fluidd" => "1.34.3",
          "kamp" => "b0dad8ec9ee31cb644b94e39d4b8a8fb9d6c9ba0",
          "klipper" => "0.13.0-unstable-2025-08-15",
          "klipperscreen" => "5ba4a1ff134ac1eba236043b8ec316c2298846e5",
          "linux" => "6.12.34-stable_20250702",
          "moonraker" => "0.9.3-unstable-2025-08-01",
          "nginx" => "1.28.0",
          "nixos-hardware" => "db030f62a449568345372bd62ed8c5be4824fa49",
          "nixpkgs" => "e6cb50b7edb109d393856d19b797ba6b6e71a4fc",
          "plymouth" => "24.004.60",
          "shaketune" => "c8ef451ec4153af492193ac31ed7eea6a52dbe4e",
          "wayland" => "1.24.0",
          "z_calibration" => "487056ac07e7df082ea0b9acc7365b4a9874889e"
        }
        |> JSON.encode!()
      )

    assert response(conn, :ok)

    image = Repo.reload!(image)
    assert image.current_versions_updated_at
    assert %Images.Versions{cage: "0.2.0"} = image.current_versions
  end

  test "404s when signature doesn't verify", %{conn: conn} do
    conn =
      put(conn, ~p"/images/not-a-uuid/not-a-datetime/not-a-sig/versions", %{"fluidd" => "1.2.3"})

    assert response(conn, :not_found)
  end
end
