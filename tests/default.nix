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
  testScript = builtins.readFile ./default.py;
}
