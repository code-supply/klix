{ lib, ... }:
{
  services.fluidd = {
    enable = true;
  };

  services.nginx.clientMaxBodySize = "100m";

  boot = {
    consoleLogLevel = lib.mkDefault 3;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "udev.log_priority=3"
      "rd.systemd.show_status=auto"
    ];
    loader.timeout = 0;
  };
}
