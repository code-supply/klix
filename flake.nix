{
  nixConfig = {
    builders = "ssh://klix.code.supply aarch64-linux - 15 - kvm,nixos-test,big-parallel";
    extra-substituters = [
      "https://nixos-raspberrypi.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-nooverrides = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi";

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
      nixos-raspberrypi,
      klipperscreen,
      ...
    }@inputs:
    let
      forAllSystems =
        generate:
        nixpkgs.lib.genAttrs
          [
            "aarch64-darwin"
            "x86_64-darwin"
            "aarch64-linux"
            "x86_64-linux"
          ]
          (
            system:
            generate (
              import nixpkgs {
                inherit system;
                overlays = [
                  (final: prev: {
                    beamPackages119 = prev.beamMinimal28Packages.extend (_: prev: { elixir = prev.elixir_1_19; });
                  })
                ];
              }
            )
          );

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
              url = prev.callPackage ./pkgs/url { };
            })
          ];
        };
      };
    in
    {
      nixosModules = modules // {
        default = {
          imports = builtins.attrValues modules;
        };
      };

      checks = forAllSystems (
        { pkgs, ... }: pkgs.callPackages ./tests { imports = builtins.attrValues modules; }
      );

      devShells = forAllSystems (
        { pkgs, ... }:
        {
          default = pkgs.callPackage ./shell.nix { beamPackages = pkgs.beamPackages119; };
        }
      );

      lib = {
        machineImports = {
          raspberry-pi-4 = [
            nixos-raspberrypi.nixosModules.raspberry-pi-4.base
          ];

          raspberry-pi-5 = [
            nixos-raspberrypi.nixosModules.raspberry-pi-5.base
            nixos-raspberrypi.nixosModules.raspberry-pi-5.page-size-16k
          ];
        };

        nixosSystem =
          args:
          nixos-raspberrypi.lib.nixosInstaller {
            specialArgs = inputs;
            modules = [
              nixos-raspberrypi.inputs.nixos-images.nixosModules.sdimage-installer
              self.nixosModules.default
              (
                {
                  config,
                  lib,
                  modulesPath,
                  ...
                }:
                {
                  disabledModules = [
                    # disable the sd-image module that nixos-images uses
                    (modulesPath + "/installer/sd-card/sd-image-aarch64-installer.nix")
                  ];
                  # nixos-images sets this with `mkForce`, thus `mkOverride 40`
                  image.baseName =
                    let
                      cfg = config.boot.loader.raspberryPi;
                    in
                    lib.mkOverride 40 "nixos-installer-rpi${cfg.variant}-${cfg.bootloader}";

                }
              )
            ]
            ++ args.modules;
          };
      };

      packages = forAllSystems (
        { pkgs, ... }:
        with pkgs;
        {
          default = callPackage ./web {
            beamPackages = pkgs.beamPackages119;
            version = if self ? rev then "0.0.0-${self.rev}" else "0.0.0-dev";
          };
          url = callPackage ./pkgs/url { };
        }
      );

      versions =
        with nixpkgs.lib.attrsets;
        let
          inputsWithRevisions = (filterAttrs (name: input: input ? rev) inputs);
          versionsFromInputs = mapAttrs (name: input: input.rev) inputsWithRevisions;
          nixpkgsPackages = [
            "cage"
            "fluidd"
            "klipper"
            "moonraker"
            "nginx"
            "plymouth"
            "wayland"
          ];
          versionsFromNixpkgs = builtins.listToAttrs (
            map (name: {
              name = name;
              value = nixpkgs.legacyPackages.aarch64-linux.${name}.version;
            }) nixpkgsPackages
          );
          kernelVersion = {
            linux =
              (self.lib.nixosSystem {
                modules = [
                  { nixpkgs.hostPlatform = "aarch64-linux"; }
                ];
              }).config.boot.kernelPackages.kernel.version;
          };
        in
        versionsFromInputs // versionsFromNixpkgs // kernelVersion;
    };
}
