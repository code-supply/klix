{
  nixosTest,
  imports,
  writeTextDir,
}:

{
  withMutableConfig = nixosTest {
    name = "Test Klix with empty mutable config";
    nodes.printer = {
      inherit imports;

      # deliberately unset
      # services.klix.configDir = "";

      services.klipperscreen.enable = true;

      services.klipper = {
        plugins = {
          kamp.enable = true;
          shaketune.enable = true;
          z_calibration.enable = true;
        };
      };
    };

    testScript = builtins.readFile ./default.py;
  };

  withNixConfig = nixosTest {
    name = "Test Klix with defined config";
    nodes.printer = {
      inherit imports;

      services.klipperscreen.enable = true;

      services.klix.configDir = writeTextDir "printer.cfg" "";

      services.klipper = {
        plugins = {
          kamp.enable = true;
          shaketune.enable = true;
          z_calibration.enable = true;
        };
      };
    };

    testScript = builtins.readFile ./default.py;
  };
}
