{
  testers,
  imports,
  writeTextDir,
}:

{
  withMutableConfig = testers.nixosTest {
    name = "Test Klix with default mutable config";
    nodes.printer = {
      inherit imports;

      # deliberately unset
      # services.klix.configDir = "";

      services.klipper = {
        plugins = {
          kamp.enable = true;
          shaketune.enable = true;
          z_calibration.enable = true;
        };
      };
    };

    testScript = builtins.readFile ./mutable_config.py;
  };

  withNixConfig = testers.nixosTest {
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

    testScript = builtins.readFile ./immutable_config.py;
  };
}
