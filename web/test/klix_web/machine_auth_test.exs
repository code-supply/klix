defmodule KlixWeb.MachineAuthTest do
  use KlixWeb.ConnCase, async: true

  alias Klix.Accounts.Scope
  alias KlixWeb.MachineAuth

  import Klix.AccountsFixtures

  @moduletag :tmp_dir

  setup %{conn: conn} do
    user = user_fixture()

    {:ok, image} =
      user
      |> Scope.for_user()
      |> Images.create(Factory.params(:image))

    datetime = DateTime.utc_now() |> DateTime.to_iso8601()

    %{
      user: user,
      conn: conn,
      image: image,
      datetime: datetime
    }
  end

  test "assume first request is genuine, and record public key found in SSHSIG", %{
    conn: conn,
    image: image,
    datetime: datetime,
    tmp_dir: dir
  } do
    signature = signature(dir, image, datetime)

    conn =
      %{
        conn
        | params: %{
            "uuid" => image.uri_id,
            "datetime" => Base.encode64(datetime),
            "sshsig" => Base.encode64(signature)
          }
      }
      |> MachineAuth.fetch_current_scope_for_machine([])

    assert conn.assigns.current_scope.image.id == image.id
    assert Klix.Repo.reload(image).host_public_key |> byte_size() == 32
  end

  test "when first request signature doesn't verify, scope is nil", %{
    conn: conn,
    datetime: datetime,
    image: image,
    tmp_dir: dir
  } do
    signature = signature(dir, image, datetime)
    bad_datetime = DateTime.to_iso8601(~U[3000-01-01 00:00:00Z])

    conn =
      %{
        conn
        | params: %{
            "uuid" => image.uri_id,
            "datetime" => Base.encode64(bad_datetime),
            "sshsig" => Base.encode64(signature)
          }
      }
      |> MachineAuth.fetch_current_scope_for_machine([])

    assert conn.assigns.current_scope == nil
    refute Repo.reload(image).host_public_key
  end

  test "when stored host key doesn't match subsequent requests, scope is nil", %{
    conn: conn,
    image: image,
    datetime: datetime,
    tmp_dir: dir
  } do
    signature = signature(dir, image, datetime)
    {:ok, _image} = Images.set_host_public_key(image, "original-key")

    conn =
      %{
        conn
        | params: %{
            "uuid" => image.uri_id,
            "datetime" => Base.encode64(datetime),
            "sshsig" => Base.encode64(signature)
          }
      }
      |> MachineAuth.fetch_current_scope_for_machine([])

    assert conn.assigns.current_scope == nil
    assert Repo.reload(image).host_public_key == "original-key"
  end

  test "when image doesn't exist, scope is nil", %{
    conn: conn,
    image: image,
    datetime: datetime,
    tmp_dir: dir
  } do
    signature = signature(dir, image, datetime)

    conn =
      %{
        conn
        | params: %{
            "uuid" => Ecto.UUID.generate(),
            "datetime" => Base.encode64(datetime),
            "sshsig" => Base.encode64(signature)
          }
      }
      |> MachineAuth.fetch_current_scope_for_machine([])

    assert conn.assigns.current_scope == nil
  end

  test "when date is too old, scope is nil", %{
    conn: conn,
    image: image,
    tmp_dir: dir
  } do
    datetime =
      DateTime.utc_now()
      |> DateTime.add(-6, :minute)
      |> DateTime.to_iso8601()

    signature = signature(dir, image, datetime)

    conn =
      %{
        conn
        | params: %{
            "uuid" => image.uri_id,
            "datetime" => Base.encode64(datetime),
            "sshsig" => Base.encode64(signature)
          }
      }
      |> MachineAuth.fetch_current_scope_for_machine([])

    assert conn.assigns.current_scope == nil
  end

  test "when date is too far in future, scope is nil", %{
    conn: conn,
    image: image,
    tmp_dir: dir
  } do
    datetime =
      DateTime.utc_now()
      |> DateTime.add(6, :minute)
      |> DateTime.to_iso8601()

    signature = signature(dir, image, datetime)

    conn =
      %{
        conn
        | params: %{
            "uuid" => image.uri_id,
            "datetime" => Base.encode64(datetime),
            "sshsig" => Base.encode64(signature)
          }
      }
      |> MachineAuth.fetch_current_scope_for_machine([])

    assert conn.assigns.current_scope == nil
  end

  defp signature(dir, image, datetime) do
    message = "#{image.uri_id}#{datetime}"

    {signature, 0} =
      System.shell("""
      ssh-keygen -q -f "#{dir}/mykey" -N ""
      echo -n #{message} | ssh-keygen -q -Y sign -n file -f "#{dir}/mykey"
      """)

    signature
  end
end
