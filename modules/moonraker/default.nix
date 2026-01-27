{
  users.users.moonraker.extraGroups = [ "klipper" ];
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
  systemd.tmpfiles.rules = [
    "d /var/lib/moonraker/logs 0775 moonraker moonraker -"
  ];
}
