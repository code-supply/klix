defmodule Klix.ImagesTest do
  use Klix.DataCase, async: true
  use ExUnitProperties

  @valid_params %{"hostname" => "my-printer", "public_key" => "my-ssh-key"}

  test "converts to a Nix flake" do
    {:ok, image} =
      Klix.Images.create(%{
        "hostname" => "some-printer",
        "timezone" => "Europe/Madrid",
        "public_key" => "a-valid-key",
        "klipperscreen_enabled" => false,
        "plugin_kamp_enabled" => true,
        "plugin_shaketune_enabled" => false,
        "plugin_z_calibration_enabled" => true
      })

    assert Klix.Images.to_flake(image) ==
             """
             {
               inputs = {
                 nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
                 klix = {
                   url = "github:code-supply/klix";
                   inputs.nixpkgs.follows = "nixpkgs";
                 };
               };

               outputs =
                 {
                   self,
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
                           "a-valid-key"
                         ];
                         services.klix.configDir = ./klipper;
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
                 }
             }
             """
  end

  describe "SSH key" do
    test "must be present" do
      {:error, changeset} = Klix.Images.create(%{})
      assert changeset.errors[:public_key] == {"can't be blank", [validation: :required]}
    end
  end

  describe "hostname" do
    test "must be present" do
      {:error, changeset} = Klix.Images.create(%{})
      assert changeset.errors[:hostname] == {"can't be blank", [validation: :required]}
    end

    property "valid when string of a-zA-Z 0-9 or hyphen" do
      check all hostname <- Klix.Hostname.generator() do
        assert {:ok, _} = Klix.Images.create(Map.put(@valid_params, "hostname", hostname))
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
  end
end
