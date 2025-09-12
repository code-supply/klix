{
  beamPackages,
  callPackages,
  version,
}:

beamPackages.mixRelease {
  pname = "klix";
  inherit version;

  mixNixDeps = callPackages ./deps.nix { };

  src = ./.;
}
