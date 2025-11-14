{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
let
  cfg = config.services.klix;
  enabledPlugins = lib.filterAttrs (
    name: pluginCfg: pluginCfg.enable
  ) config.services.klipper.plugins;
  enabledPluginDefinitions = map (name: plugins.${name}) (builtins.attrNames enabledPlugins);

  extraPythonPackages =
    p:
    builtins.concatMap (
      plugin: if plugin ? deps then (plugin.deps p) else [ ]
    ) enabledPluginDefinitions;

  plugins = import ./plugins;
in
{
  options = {
    services.klix.configDir = lib.mkOption { example = "./klipper"; };
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

    services.klipper =
      let
        userConfigDir = cfg.configDir;
        configs = pkgs.runCommand "create-printer-config" { } ''
          mkdir $out
          # all includes get replaced with the user's config dir as base
          # except: includes prefixed with extras/ get replaced with the klipper drv's extras dir, where plugins live
          sed '/\[include extras\//! s#\[include \(.*\)\]#[include ${userConfigDir}/\1]#;s#\[include extras/#[include ${config.services.klipper.package}/lib/klipper/extras/#' \
          < ${userConfigDir}/printer.cfg \
          > $out/printer.cfg
        '';
      in

      {
        enable = true;

        configFile = if (isNull config.services.klipper.settings) then "${configs}/printer.cfg" else null;

        logFile = "/var/lib/klipper/klipper.log";
        user = "klipper";
        group = "klipper";

        package =
          with inputs.nixpkgs-nooverrides.legacyPackages.${pkgs.stdenv.hostPlatform.system};
          (klipper.override {
            inherit extraPythonPackages;
          }).overrideAttrs
            {
              postUnpack = lib.concatMapAttrsStringSep "\n" (
                name: pluginCfg:
                let
                  plugin = plugins.${name};
                  pluginSrc = inputs.${name};
                  dest = if plugin.configLink ? to then plugin.configLink.to else plugin.configLink.from;
                in
                "ln -sfv ${pluginSrc}/${plugin.configLink.from} source/klippy/extras/${dest}"
              ) enabledPlugins;
            };
      };
  };
}
