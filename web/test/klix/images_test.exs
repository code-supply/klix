defmodule Klix.ImagesTest do
  use Klix.DataCase, async: true
  use ExUnitProperties

  test "setting the output path broadcasts the path" do
    {:ok, %{builds: [build]} = image} =
      Klix.Factory.params(:image)
      |> Klix.Images.create()

    Klix.Images.subscribe(image.id)

    {:ok, build} = Klix.Images.set_build_output_path(build, "/nix/store/blah")

    assert_receive build_ready: ^build
  end

  describe "getting the next build" do
    test "nil when there's no build" do
      assert Klix.Images.next_build() == nil
    end

    test "nil when all builds have output paths" do
      {:ok, %{builds: [build]}} =
        Klix.Factory.params(:image)
        |> Klix.Images.create()

      Klix.Images.set_build_output_path(build, "/some/path")

      assert Klix.Images.next_build() == nil
    end

    test "preloaded with image when available" do
      {:ok, %{builds: [initial_build]} = image} =
        Klix.Factory.params(:image)
        |> Klix.Images.create()

      build = Klix.Images.next_build()
      assert build.id == initial_build.id
      assert build.image_id == image.id
    end

    test "chooses the oldest build" do
      _new =
        struct!(
          Klix.Images.Build,
          Klix.Factory.params(:build, inserted_at: ~U[3000-01-01 00:00:00Z])
        )
        |> Klix.Repo.insert!()

      old =
        struct!(
          Klix.Images.Build,
          Klix.Factory.params(:build, inserted_at: ~U[2000-01-01 00:00:00Z])
        )
        |> Klix.Repo.insert!()

      assert Klix.Images.next_build().id == old.id
    end
  end

  test "converts to a Nix flake" do
    {:ok, image} =
      Klix.Factory.params(
        :image,
        klipper_config: [
          type: :github,
          owner: "mr-print",
          repo: "my-klipper-config"
        ],
        hostname: "some-printer",
        timezone: "Europe/Madrid",
        klipperscreen_enabled: false,
        plugin_kamp_enabled: true,
        plugin_shaketune_enabled: false,
        plugin_z_calibration_enabled: true
      )
      |> Klix.Images.create()

    assert Klix.Images.to_flake(image) ==
             """
             {
               inputs = {
                 nixpkgs.url = "github:NixOS/nixpkgs/e6cb50b7edb109d393856d19b797ba6b6e71a4fc";
                 klipperConfig = {
                   type = "github";
                   owner = "mr-print";
                   repo = "my-klipper-config";
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
                   packages.aarch64-linux.image = self.nixosConfigurations.some-printer.config.system.build.sdImage;
                   nixosConfigurations.some-printer = nixpkgs.lib.nixosSystem {
                     modules = [
                       klix.nixosModules.default
                       {
                         networking.hostName = "some-printer";
                         time.timeZone = "Europe/Madrid";
                         system.stateVersion = "25.05";
                         users.users.klix.openssh.authorizedKeys.keys = [
                           "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINxmQDDdlqsMmQ69TsBWxqFOPfyipAX0h+4GGELsGRup nobody@ever"
                         ];
                         services.klix.configDir = "${klipperConfig}/boxes/ketchup-king/klipper";
                         services.klipper = {
                           plugins = {
                             kamp.enable = true;
                             shaketune.enable = false;
                             z_calibration.enable = true;
                           };
                         };

                         services.klipperscreen.enable = false;
                       }
                     ];
                   };
                 };
             }
             """
  end

  describe "SSH key" do
    test "must be present" do
      {:error, changeset} = Klix.Images.create(%{})
      assert changeset.errors[:public_key] == {"can't be blank", [validation: :required]}
    end

    test "must be a valid key" do
      {:error, changeset} = Klix.Images.create(%{"public_key" => "invalid key"})

      assert changeset.errors[:public_key] ==
               {"not a valid key", [validation: :key_decode_failed]}
    end
  end

  describe "hostname" do
    test "must be present" do
      {:error, changeset} = Klix.Images.create(%{})
      assert changeset.errors[:hostname] == {"can't be blank", [validation: :required]}
    end

    property "valid when string of a-zA-Z 0-9 or hyphen" do
      check all hostname <- Klix.Hostname.generator() do
        assert {:ok, _} = Klix.Factory.params(:image, hostname: hostname) |> Klix.Images.create()
      end
    end

    property "invalid if longer than 253 characters" do
      check all hostname <- string(:ascii, min_length: 254) do
        {:error, changeset} = Klix.Images.create(%{"hostname" => hostname})

        assert changeset.errors[:hostname] ==
                 {"should be at most %{count} character(s)",
                  [{:count, 253}, {:validation, :length}, {:kind, :max}, {:type, :string}]}
      end
    end

    test "hostname may not start or end with a hyphen" do
      {:error, starts_with_hyphen} = Klix.Images.create(%{"hostname" => "-foo"})
      {:error, ends_with_hyphen} = Klix.Images.create(%{"hostname" => "foo-"})

      assert starts_with_hyphen.errors[:hostname] ==
               {"must not start with a hyphen", validation: :format}

      assert ends_with_hyphen.errors[:hostname] ==
               {"must not end with a hyphen", validation: :format}
    end

    test "hostname can't have dodgy characters" do
      {:error, backtick} = Klix.Images.create(%{"hostname" => "`"})
      {:error, dot} = Klix.Images.create(%{"hostname" => "a.b"})

      assert backtick.errors[:hostname] ==
               {"must be A-Za-z0-9 or hyphen", validation: :format}

      assert dot.errors[:hostname] ==
               {"must be A-Za-z0-9 or hyphen", validation: :format}
    end
  end

  describe "timezone" do
    test "must be in the list" do
      {:error, image} = Klix.Images.create(%{"timezone" => "Not/AZone"})

      assert {"must be a valid timezone", [{:validation, :inclusion} | _]} =
               image.errors[:timezone]
    end
  end

  describe "Klipper config" do
    test "must be present" do
      {:error, changeset} = Klix.Images.create(%{})
      assert changeset.errors[:klipper_config] == {"can't be blank", [validation: :required]}
    end
  end
end
