{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    klipperscreen = {
      url = "github:KlipperScreen/KlipperScreen";
      flake = false;
    };

    kamp = {
      url = "github:kyleisah/Klipper-Adaptive-Meshing-Purging";
      flake = false;
    };

    shaketune = {
      url = "github:Frix-x/klippain-shaketune";
      flake = false;
    };

    z_calibration = {
      url = "github:protoloft/klipper_z_calibration";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixos-hardware,
      klipperscreen,
      ...
    }@inputs:
    let
      forAllSystems =
        generate:
        nixpkgs.lib.genAttrs [
          "aarch64-darwin"
          "x86_64-darwin"
          "aarch64-linux"
          "x86_64-linux"
        ] (system: generate (import nixpkgs { inherit system; }));

      modules = {
        set-inputs._module.args = { inherit inputs; };
        fluidd = import ./modules/fluidd;
        klipper = import ./modules/klipper;
        klipperscreen = import ./modules/klipperscreen;
        moonraker = import ./modules/moonraker;
        plymouth = import ./modules/plymouth;
        system = import ./modules/system;

        overlays = {
          nixpkgs.overlays = [
            (final: prev: {
              klipperscreen = prev.klipperscreen.overrideAttrs {
                src = klipperscreen;
              };
            })
          ];
        };
      };
    in
    {
      nixosModules = modules // {
        default = {
          imports = builtins.attrValues modules ++ [
            { nixpkgs.hostPlatform = "aarch64-linux"; }
            nixos-hardware.nixosModules.raspberry-pi-4
            ./modules/system/raspberry-pi.nix
          ];
        };
      };

      checks = forAllSystems (
        { pkgs, ... }:
        {
          default = pkgs.callPackage ./tests { imports = builtins.attrValues modules; };
        }
      );

      devShells = forAllSystems (
        { pkgs, ... }:
        {
          default = pkgs.callPackage ./shell.nix { };
        }
      );

      packages = forAllSystems (
        { pkgs, ... }:
        {
          default = pkgs.callPackage ./web {
            version = if self ? rev then "0.0.0-${self.rev}" else "0.0.0-dev";
          };
        }
      );
    };
}
