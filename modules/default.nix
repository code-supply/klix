{
  config = {
    imports = [
      ./klipper
    ];
    users = {
      users = {
        moonraker.extraGroups = [ "klipper" ];
      };
    };

    security.polkit.enable = true;

    services.moonraker = {
      enable = true;
      address = "0.0.0.0";
      allowSystemControl = true;
      settings = {
        octoprint_compat = { };
        authorization = {
          force_logins = false;
          trusted_clients = [
            "0.0.0.0/0"
          ];
          cors_domains = [
            "*"
          ];
        };
        file_manager = {
          enable_object_processing = true;
        };
      };
    };

    services.fluidd = {
      enable = true;
    };

    services.nginx.clientMaxBodySize = "100m";

    boot = {
      consoleLogLevel = 3;
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
  };
}
