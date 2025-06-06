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
      settings = {
        mcu.serial = "/dev/corn-flakes";
        printer = {
          kinematics = "corexy";
          max_accel = 1;
          max_velocity = 1;
        };

        stepper_x = {
          step_pin = "PF0";
          dir_pin = "PF1";
          enable_pin = "!PD7";
          microsteps = 16;
          rotation_distance = 40;
          endstop_pin = "^PE5";
          position_endstop = 0;
          position_max = 200;
          homing_speed = 50;
        };

        stepper_y = {
          step_pin = "PF6";
          dir_pin = "PF7";
          enable_pin = "!PF2";
          microsteps = 16;
          rotation_distance = 40;
          endstop_pin = "^PJ1";
          position_endstop = 0;
          position_max = 200;
          homing_speed = 50;
        };

        stepper_z = {
          step_pin = "PL3";
          dir_pin = "PL1";
          enable_pin = "!PK0";
          microsteps = 16;
          rotation_distance = 8;
          endstop_pin = "^PD3";
          position_endstop = 0.5;
          position_max = 200;
        };

        z_calibration = { };
      };
      plugins = {
        kamp.enable = true;
        shaketune.enable = true;
        z_calibration.enable = true;
      };
    };
  };
  testScript = builtins.readFile ./default.py;
}
