{
  testers,
  imports,
  writeTextDir,
}:

{
  mutableConfig = testers.nixosTest {
    name = "Mutable config";
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

  immutableConfig = testers.nixosTest {
    name = "Immutable config";
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
