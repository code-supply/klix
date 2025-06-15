{ pkgs, ... }:

{
  boot.plymouth = {
    enable = true;
    logo = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/VoronDesign/Voron-Documentation/a74b763bb5eaa93d1e566d662de9f4d01caf44a1/images/voron_design_logo.png";
      hash = "sha256-6rWw6pX4VnPdNW9Xa9bZed9AllClfFO3RU0xTGZRmvY=";
    };
  };
}
