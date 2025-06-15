let
  username = "klix";
in
{
  users.users.${username} = {
    isNormalUser = true;
    description = "Klix";
    extraGroups = [
      "dialout"
      "disk"
      "networkmanager"
      "video"
      "wheel"
    ];
  };

  services.displayManager.autoLogin = {
    enable = true;
    user = username;
  };
}
