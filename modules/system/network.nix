{ lib, ... }:

{
  networking = {
    firewall.enable = false;
    networkmanager.enable = lib.mkForce true;
    wireless.enable = lib.mkForce false;
    wireless.iwd.enable = lib.mkForce false;
  };
  systemd.services.systemd-networkd-wait-online.enable = lib.mkForce false;
}
