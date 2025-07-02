let
  username = "klix";
in
{
  users.users.${username} = {
    isNormalUser = true;
    description = "Klix";
    group = username;
    extraGroups = [
      "dialout"
      "disk"
      "networkmanager"
      "video"
      "wheel"
    ];
  };
  users.groups.${username} = { };

  security.sudo.wheelNeedsPassword = false;

  services.displayManager.autoLogin = {
    enable = true;
    user = username;
  };
}
