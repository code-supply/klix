{ lib, ... }:

{
  networking = {
    firewall.enable = false;
    networkmanager.enable = true;
  };
  systemd.services.systemd-networkd-wait-online.enable = lib.mkForce false;
}
