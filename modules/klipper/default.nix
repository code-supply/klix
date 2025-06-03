{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.services.klipper;

  enabledPlugins = lib.filterAttrs (name: pluginCfg: pluginCfg.enable) cfg.plugins;
  enabledPluginDefinitions = map (name: plugins.${name}) (builtins.attrNames enabledPlugins);

  extraPythonPackages =
    p:
    builtins.concatMap (
      plugin: if plugin ? deps then (plugin.deps p) else [ ]
    ) enabledPluginDefinitions;

  plugins = {
    kamp = {
      description = "Klipper Adaptive Meshing & Purging";
      configLink.from = "Configuration";
      configLink.to = "KAMP";
      src = pkgs.fetchFromGitHub {
        owner = "kyleisah";
        repo = "Klipper-Adaptive-Meshing-Purging";
        rev = "b0dad8ec9ee31cb644b94e39d4b8a8fb9d6c9ba0";
        hash = "sha256-05l1rXmjiI+wOj2vJQdMf/cwVUOyq5d21LZesSowuvc=";
      };
    };
    shaketune = {
      description = "Klipper streamlined input shaper workflow and calibration tools";
      configLink.from = "shaketune";
      src = pkgs.fetchFromGitHub {
        owner = "Frix-x";
        repo = "klippain-shaketune";
        rev = "c8ef451ec4153af492193ac31ed7eea6a52dbe4e";
        hash = "sha256-zzskp7ZiwR7nJ2e5eTCyEilctDoRxZdBn90zncFm0Rw=";
      };
      deps =
        p: with p; [
          GitPython
          matplotlib
          numpy
          scipy
          pywavelets
          zstandard
        ];
    };
    z_calibration = {
      description = "Klipper plugin for self-calibrating z-offset";
      configLink.from = "z_calibration.py";
      src = pkgs.fetchFromGitHub {
        owner = "protoloft";
        repo = "klipper_z_calibration";
        rev = "487056ac07e7df082ea0b9acc7365b4a9874889e";
        hash = "sha256-WWP0LqhJ3ET4nxR8hVpq1uMOSK+CX7f3LXjOAZbRY8c=";
      };
    };
  };
in
{
  options = {
    services.klipper.plugins = builtins.mapAttrs (name: definition: {
      enable = lib.mkEnableOption definition.description;
    }) plugins;
  };

  config = {
    users = {
      users = {
        klipper = {
          isSystemUser = true;
          group = "klipper";
          home = "/home/klipper";
          createHome = true;
        };
      };
      groups.klipper = { };
    };

    services.klipper = {
      enable = true;

      logFile = "/var/lib/klipper/klipper.log";
      user = "klipper";
      group = "klipper";

      package =
        (pkgs.klipper.override {
          inherit extraPythonPackages;
        }).overrideAttrs
          {
            postUnpack = pkgs.lib.concatMapAttrsStringSep "\n" (
              name: pluginCfg:
              let
                plugin = plugins.${name};
                dest = if plugin.configLink ? to then plugin.configLink.to else plugin.configLink.from;
              in
              "ln -sfv ${plugin.src}/${plugin.configLink.from} source/klippy/extras/${dest}"
            ) enabledPlugins;
          };
    };
  };
}
