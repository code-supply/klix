{ pkgs, lib, ... }:

{
  imports = [
    ./network.nix
    ./user.nix
  ];

  environment.systemPackages = [ pkgs.url ];

  boot = {
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

  nix.settings = {
    download-buffer-size = 524288000;
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      "@wheel"
    ];
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = lib.mkForce "no";
      UseDns = false;
    };
  };
}
