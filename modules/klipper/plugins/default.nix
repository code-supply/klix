{ fetchFromGitHub }:

{
  kamp = {
    description = "Klipper Adaptive Meshing & Purging";
    configLink.from = "Configuration";
    configLink.to = "KAMP";
    src = fetchFromGitHub {
      owner = "kyleisah";
      repo = "Klipper-Adaptive-Meshing-Purging";
      rev = "b0dad8ec9ee31cb644b94e39d4b8a8fb9d6c9ba0";
      hash = "sha256-05l1rXmjiI+wOj2vJQdMf/cwVUOyq5d21LZesSowuvc=";
    };
  };

  shaketune = {
    description = "Klipper streamlined input shaper workflow and calibration tools";
    configLink.from = "shaketune";
    src = fetchFromGitHub {
      owner = "Frix-x";
      repo = "klippain-shaketune";
      rev = "c8ef451ec4153af492193ac31ed7eea6a52dbe4e";
      hash = "sha256-zzskp7ZiwR7nJ2e5eTCyEilctDoRxZdBn90zncFm0Rw=";
    };
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
    src = fetchFromGitHub {
      owner = "protoloft";
      repo = "klipper_z_calibration";
      rev = "487056ac07e7df082ea0b9acc7365b4a9874889e";
      hash = "sha256-WWP0LqhJ3ET4nxR8hVpq1uMOSK+CX7f3LXjOAZbRY8c=";
    };
  };
}
