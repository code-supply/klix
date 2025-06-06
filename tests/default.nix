{ pkgs }:

pkgs.nixosTest {
  name = "Test Klix functionality";
  nodes.printer = {
    imports = [
      ../modules/boot
      ../modules/fluidd
      ../modules/klipper
      ../modules/moonraker
    ];
    services.klipper = {
      settings = { };
      plugins = {
        kamp.enable = true;
        shaketune.enable = true;
        z_calibration.enable = true;
      };
    };
  };
  testScript = ''
    moonraker_port = 7125
    nginx_port = 80
    printer.wait_for_open_port(port = moonraker_port, timeout = 10)
    printer.wait_for_open_port(port = nginx_port, timeout = 10)
  '';
}
