defmodule Klix.ImagesTest do
  use Klix.DataCase, async: true
  use ExUnitProperties

  import Klix.ToNix

  setup do: %{scope: user_fixture() |> Scope.for_user()}

  test "can get friendly machine name" do
    assert Images.friendly_machine_name(%Images.Image{machine: :raspberry_pi_4}) ==
             "Raspberry Pi 4"

    assert Images.friendly_machine_name(%Images.Image{machine: :raspberry_pi_5}) ==
             "Raspberry Pi 5"

    assert Images.friendly_machine_name(%Images.Image{}) == nil
  end

  describe "soft deletion" do
    setup %{scope: scope} do
      {:ok, image} = Images.create(scope, Klix.Factory.params(:image))
      %{image: image}
    end

    test "hides image from lists and finds", %{scope: scope, image: image} do
      {:ok, _image} = Images.soft_delete(scope, image)

      [build] = image.builds

      assert Images.list() == []
      assert Images.list(scope) == []
      assert Images.find(image.uri_id) == nil
      assert_raise Ecto.NoResultsError, fn -> Images.find!(image.uri_id) end
      assert Images.find_build(scope, image.id, build.id) == nil

      assert Repo.preload(build, :image).image == nil
    end

    test "must be done by the owner", %{image: image} do
      another_scope = user_fixture() |> Scope.for_user()
      {:error, :invalid_scope} = Images.soft_delete(another_scope, image)
    end

    test "is still in the database", %{scope: scope, image: image} do
      {:ok, _image} = Images.soft_delete(scope, image)
      assert %Images.Image{} = Repo.get(Images.Image, image.id)
    end
  end

  describe "download URL" do
    test "uses https" do
      assert Images.download_url(%Images.Build{id: 123}) |> String.starts_with?("https://")
    end
  end

  describe "completing with success" do
    setup %{scope: scope} do
      {:ok, %{builds: [build]} = image} = Images.create(scope, Klix.Factory.params(:image))
      Images.subscribe(image.id)
      {:ok, build} = Images.build_completed(build)

      %{build: build}
    end

    test "sets completion time", %{build: build} do
      assert Enum.min([build.completed_at, DateTime.utc_now()]) == build.completed_at
    end

    test "broadcasts", %{build: build} do
      assert_receive build_ready: ^build
    end
  end

  describe "completing with error" do
    setup %{scope: scope} do
      {:ok, %{builds: [build]} = image} = Images.create(scope, Klix.Factory.params(:image))
      Images.subscribe(image.id)
      {:ok, build} = Images.build_failed(build, "some error")

      %{build: build}
    end

    test "sets completion time", %{build: build} do
      assert Enum.min([build.completed_at, DateTime.utc_now()]) == build.completed_at
    end

    test "sets error text", %{build: build} do
      assert build.error == "some error"
    end

    test "broadcasts", %{build: build} do
      assert_receive build_ready: ^build
    end
  end

  test "can get duration of builds" do
    one_minute = %Images.Build{
      inserted_at: ~U[2000-01-01 00:00:00Z],
      completed_at: ~U[2000-01-01 00:01:00Z]
    }

    incomplete = %Images.Build{
      inserted_at: ~U[2000-01-01 00:00:00Z],
      completed_at: nil
    }

    assert Images.build_duration(one_minute) == ~T[00:01:00]
    assert Images.build_duration(incomplete, ~U[2000-01-01 00:00:01Z]) == ~T[00:00:01]
  end

  describe "listing and finding" do
    setup do
      user_1 = user_fixture()
      user_2 = user_fixture()
      scope_1 = Scope.for_user(user_1)
      scope_2 = Scope.for_user(user_2)

      {:ok, %{id: id_1, builds: [%{id: build_id_1}]}} =
        Images.create(scope_1, Klix.Factory.params(:image))

      %{id_1: id_1, scope_1: scope_1, scope_2: scope_2, build_id_1: build_id_1}
    end

    test "can list all images, for admin purposes", %{id_1: id_1, scope_2: scope_2} do
      assert [%{id: ^id_1}] = Images.list()
      {:ok, %{id: id_2}} = Images.create(scope_2, Klix.Factory.params(:image))
      assert [%{id: ^id_2}, %{id: ^id_1}] = Images.list()
    end

    test "can be listed for a given scope", %{id_1: id, scope_1: scope_1, scope_2: scope_2} do
      assert [%{id: ^id}] = Images.list(scope_1)
      assert [] = Images.list(scope_2)
    end

    test "can't find another user's image", %{scope_2: scope_2, id_1: id_1} do
      assert_raise Ecto.NoResultsError, fn ->
        Images.find!(scope_2, id_1)
      end
    end

    test "can find own build", %{scope_1: scope, id_1: id, build_id_1: build_id} do
      assert Images.find_build(scope, id, build_id)
    end

    test "can't find another user's build", %{scope_2: scope_2, id_1: id, build_id_1: build_id} do
      refute Images.find_build(scope_2, id, build_id)
    end
  end

  @tag :tmp_dir
  test "when file is ready, record size", %{scope: scope, tmp_dir: dir} do
    {:ok, %{builds: [build]}} =
      Images.create(scope, Klix.Factory.params(:image))

    write_image(dir, "four")

    {:ok, build} = Images.file_ready(build, dir)

    assert Repo.reload!(build).byte_size == 4
  end

  test "can store large file sizes without overflowing", %{scope: scope} do
    {:ok, %{builds: [build]}} =
      Images.create(scope, Klix.Factory.params(:image))

    assert {:ok, _build} =
             build
             |> Ecto.Changeset.change(byte_size: 2_450_333_781)
             |> Repo.update()
  end

  describe "getting the next build" do
    test "nil when there's no build" do
      assert Images.next_build() == nil
    end

    test "nil when all builds have completion dates", %{scope: scope} do
      {:ok, %{builds: [build]}} =
        Images.create(scope, Klix.Factory.params(:image))

      Images.build_completed(build)

      assert Images.next_build() == nil
    end

    test "preloaded with image when available", %{scope: scope} do
      {:ok, %{builds: [initial_build]} = image} =
        Images.create(scope, Klix.Factory.params(:image))

      build = Images.next_build()
      assert build.id == initial_build.id
      assert build.image_id == image.id
    end

    test "chooses the oldest build" do
      _new =
        struct!(
          Images.Build,
          Klix.Factory.params(:build, inserted_at: ~U[3000-01-01 00:00:00Z])
        )
        |> Repo.insert!()

      old =
        struct!(
          Images.Build,
          Klix.Factory.params(:build, inserted_at: ~U[2000-01-01 00:00:00Z])
        )
        |> Repo.insert!()

      assert Images.next_build().id == old.id
    end
  end

  test "converts to a Nix flake", %{scope: scope} do
    {:ok, image} =
      Images.create(
        scope,
        Klix.Factory.params(
          :image,
          machine: :raspberry_pi_5,
          klipper_config: [
            type: :github,
            owner: "mr-print",
            repo: "my-klipper-config",
            path: "my/lovely/klipper"
          ],
          hostname: "some-printer",
          timezone: "Europe/Madrid",
          klipperscreen_enabled: false,
          plugin_kamp_enabled: true,
          plugin_shaketune_enabled: false,
          plugin_z_calibration_enabled: true
        )
      )

    {:ok, image} = Images.set_uri_id(image, "deadb33f-f33d-f00d-d00f-d0feef0f1355")

    assert to_nix(image) ==
             """
             {
               inputs = {
                 nixpkgs.url = "github:NixOS/nixpkgs/e6cb50b7edb109d393856d19b797ba6b6e71a4fc";
                 klipperConfig = {
                   type = "github";
                   owner = "mr-print";
                   repo = "my-klipper-config";
                   flake = false;
                 };
                 klix = {
                   url = "github:code-supply/klix";
                   inputs.nixpkgs.follows = "nixpkgs";
                 };
               };

               outputs =
                 {
                   self,
                   klipperConfig,
                   nixpkgs,
                   klix,
                 }:
                 {
                   packages.aarch64-linux.image = self.nixosConfigurations.default.config.system.build.sdImage;
                   nixosConfigurations.default = klix.lib.nixosSystem {
                     modules = [
                       (
                         { pkgs, ... }:
                         {
                           environment.systemPackages = [
                             (pkgs.writeShellApplication {
                               name = "klix-update";
                               runtimeInputs = [
                                 klix.packages.aarch64-linux.url
                               ];
                               text = ''
                                 dir="$(mktemp)"
                                 (
                                   cd "$dir"
                                   curl "$(klix-url #{image.uri_id} config.tar.gz#default)" | tar -x
                                   nixos-rebuild switch --flake .
                                   nix eval .#versions | curl --request PUT --json @- "$(klix-url #{image.uri_id} versions)"
                                 )
                                 rm -rf "$dir"
                               '';
                             })
                           ];
                           imports = klix.lib.machineImports.raspberry-pi-5;
                           networking.hostName = "some-printer";
                           time.timeZone = "Europe/Madrid";
                           system.stateVersion = "25.05";
                           users.users.klix.openssh.authorizedKeys.keys = [
                             "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINxmQDDdlqsMmQ69TsBWxqFOPfyipAX0h+4GGELsGRup nobody@ever"
                           ];
                           services.klix.configDir = "${klipperConfig}/my/lovely/klipper";
                           services.klipper = {
                             plugins = {
                               kamp.enable = true;
                               shaketune.enable = false;
                               z_calibration.enable = true;
                             };
                           };

                           services.klipperscreen.enable = false;
                         }
                       )
                     ];
                   };
                   versions = klix.versions;
                 };
             }
             """
  end

  describe "SSH key" do
    test "must be present", %{scope: scope} do
      {:error, changeset} = Images.create(scope, %{})
      assert changeset.errors[:public_key] == {"can't be blank", [validation: :required]}
    end

    test "must be a valid key", %{scope: scope} do
      {:error, changeset} = Images.create(scope, %{"public_key" => "invalid key"})

      assert changeset.errors[:public_key] ==
               {"not a valid key", [validation: :key_decode_failed]}
    end

    test "accidental paste of private key is detected", %{scope: scope} do
      {:error, changeset} =
        Images.create(scope, %{
          "public_key" => """
          -----BEGIN OPENSSH PRIVATE KEY-----
          b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
          QyNTUxOQAAACBGBHCf6rEwUJTXRE/yAJS0wM6gISoQp3rv43Rq6G5TAgAAAJAPH5FdDx+R
          XQAAAAtzc2gtZWQyNTUxOQAAACBGBHCf6rEwUJTXRE/yAJS0wM6gISoQp3rv43Rq6G5TAg
          AAAEATZqVIx+bofrYrEGrDCVUAFA38Gvxz8nWxuX4mXrrYj0YEcJ/qsTBQlNdET/IAlLTA
          zqAhKhCneu/jdGroblMCAAAAC2FuZHJld0BwMTRzAQI=
          -----END OPENSSH PRIVATE KEY-----\
          """
        })

      assert changeset.errors[:public_key] ==
               {"looks like a private key", [validation: :format]}
    end
  end

  describe "hostname" do
    test "must be present", %{scope: scope} do
      {:error, changeset} = Images.create(scope, %{})
      assert changeset.errors[:hostname] == {"can't be blank", [validation: :required]}
    end

    property "valid when string of a-zA-Z 0-9 or hyphen", %{scope: scope} do
      check all hostname <- Klix.Hostname.generator() do
        assert {:ok, _} =
                 Images.create(scope, Klix.Factory.params(:image, hostname: hostname))
      end
    end

    property "invalid if longer than 253 characters", %{scope: scope} do
      check all hostname <- string(:ascii, min_length: 254) do
        {:error, changeset} = Images.create(scope, %{"hostname" => hostname})

        assert changeset.errors[:hostname] ==
                 {"should be at most %{count} character(s)",
                  [{:count, 253}, {:validation, :length}, {:kind, :max}, {:type, :string}]}
      end
    end

    test "hostname may not start or end with a hyphen", %{scope: scope} do
      {:error, starts_with_hyphen} = Images.create(scope, %{"hostname" => "-foo"})
      {:error, ends_with_hyphen} = Images.create(scope, %{"hostname" => "foo-"})

      assert starts_with_hyphen.errors[:hostname] ==
               {"must not start with a hyphen", validation: :format}

      assert ends_with_hyphen.errors[:hostname] ==
               {"must not end with a hyphen", validation: :format}
    end

    test "hostname can't have dodgy characters", %{scope: scope} do
      {:error, backtick} = Images.create(scope, %{"hostname" => "`"})
      {:error, dot} = Images.create(scope, %{"hostname" => "a.b"})

      assert backtick.errors[:hostname] ==
               {"must be A-Za-z0-9 or hyphen", validation: :format}

      assert dot.errors[:hostname] ==
               {"must be A-Za-z0-9 or hyphen", validation: :format}
    end
  end

  describe "timezone" do
    test "must be in the list", %{scope: scope} do
      {:error, image} = Images.create(scope, %{"timezone" => "Not/AZone"})

      assert {"must be a valid timezone", [{:validation, :inclusion} | _]} =
               image.errors[:timezone]
    end
  end

  describe "Klipper config" do
    test "must be present", %{scope: scope} do
      {:error, changeset} = Images.create(scope, %{})
      assert changeset.errors[:klipper_config] == {"can't be blank", [validation: :required]}
    end
  end
end
