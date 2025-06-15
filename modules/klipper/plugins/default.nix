{
  kamp = {
    description = "Klipper Adaptive Meshing & Purging";
    configLink.from = "Configuration";
    configLink.to = "KAMP";
  };

  shaketune = {
    description = "Klipper streamlined input shaper workflow and calibration tools";
    configLink.from = "shaketune";
    deps =
      p: with p; [
        GitPython
        matplotlib
        numpy
        scipy
        pywavelets
        zstandard
      ];
  };

  z_calibration = {
    description = "Klipper plugin for self-calibrating z-offset";
    configLink.from = "z_calibration.py";
  };
}
