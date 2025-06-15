{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    klipperscreen = {
      url = "github:KlipperScreen/KlipperScreen";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixos-hardware,
      klipperscreen,
    }:
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
    };
}
