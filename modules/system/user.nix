let
  username = "klix";
in
{
  users.users.${username} = {
    isNormalUser = true;
    description = "Klix";
    group = "klix";
    extraGroups = [
      "dialout"
      "disk"
      "networkmanager"
      "video"
      "wheel"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  services.displayManager.autoLogin = {
    enable = true;
    user = username;
  };
}
