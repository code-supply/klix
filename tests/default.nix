{ pkgs }:

pkgs.nixosTest {
  name = "Test Klix functionality";
  nodes.printer = {
    imports = [
      ../modules
      ../modules/klipper
      ../modules/moonraker
      ../modules/fluidd
    ];
    services.klipper.settings = { };
  };
  testScript = ''
    moonraker_port = 7125
    nginx_port = 80
    printer.wait_for_open_port(port = moonraker_port, timeout = 10)
    printer.wait_for_open_port(port = nginx_port, timeout = 10)
  '';
}
