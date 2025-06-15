{
  pkgs,
  lib,
  config,
  ...
}:

{
  options = {
    services.klipperscreen.enable = lib.mkEnableOption "Whether to enable KlipperScreen";
  };

  config =
    let
      cfg = config.services.klipperscreen;
    in
    {
      services.cage = {
        enable = cfg.enable;
        user = "klix";
        program = "${pkgs.klipperscreen}/bin/KlipperScreen";
        extraArguments = [ "-ds" ];
      };
    };
}
