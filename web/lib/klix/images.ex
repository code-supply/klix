defmodule Klix.Images do
  alias __MODULE__.Image

  def find!(id) do
    Klix.Repo.get!(Image, id)
  end

  def create(attrs) do
    %Image{}
    |> Klix.Images.Image.changeset(attrs)
    |> Klix.Repo.insert()
  end

  def to_flake(%Image{} = image) do
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
          packages.aarch64-linux.image = self.nixosConfigurations.#{image.hostname}.config.system.build.sdImage;
          nixosConfigurations.#{image.hostname} = nixpkgs.lib.nixosSystem {
            modules = [
              klix.nixosModules.default
              {
                networking.hostName = "#{image.hostname}";
                time.timeZone = "#{image.timezone}";
                system.stateVersion = "25.05";
                users.users.klix.openssh.authorizedKeys.keys = [
                  "#{image.public_key}"
                ];
                services.klix.configDir = ./klipper;
                services.klipper = {
                  plugins = {
                    kamp.enable = #{image.plugin_kamp_enabled};
                    shaketune.enable = #{image.plugin_shaketune_enabled};
                    z_calibration.enable = #{image.plugin_z_calibration_enabled};
                  };
                };

                services.klipperscreen.enable = #{image.klipperscreen_enabled};
              }
            ];
          };
        }
    }
    """
  end
end
