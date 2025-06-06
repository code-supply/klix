{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      forAllSystems =
        generate:
        nixpkgs.lib.genAttrs [
          "aarch64-darwin"
          "x86_64-darwin"
          "aarch64-linux"
          "x86_64-linux"
        ] (system: generate (import nixpkgs { inherit system; }));
    in
    {
      nixosModules = {
        default = import ./modules;
        boot = import ./modules/boot;
        fluidd = import ./modules/fluidd;
        klipper = import ./modules/klipper;
        moonraker = import ./modules/moonraker;
      };

      checks = forAllSystems (
        { pkgs, ... }:
        {
          default = pkgs.callPackage ./tests { };
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
