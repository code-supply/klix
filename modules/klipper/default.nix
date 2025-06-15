{
  pkgs,
  lib,
  config,
  inputs,
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

  plugins = import ./plugins;
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
                pluginSrc = inputs.${name};
                dest = if plugin.configLink ? to then plugin.configLink.to else plugin.configLink.from;
              in
              "ln -sfv ${pluginSrc}/${plugin.configLink.from} source/klippy/extras/${dest}"
            ) enabledPlugins;
          };
    };
  };
}
