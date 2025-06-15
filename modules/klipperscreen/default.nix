{ pkgs, ... }:

{
  services.cage = {
    enable = true;
    user = "klix";
    program = "${pkgs.klipperscreen}/bin/KlipperScreen";
    extraArguments = [ "-ds" ];
  };
}
