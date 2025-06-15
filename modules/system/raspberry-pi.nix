{
  nixpkgs.overlays = [
    (final: prev: {
      # https://github.com/NixOS/nixpkgs/issues/126755#issuecomment-869149243
      makeModulesClosure = x: prev.makeModulesClosure (x // { allowMissing = true; });
    })
  ];

  hardware.raspberry-pi."4" = {
    fkms-3d.enable = true;
    touch-ft5406.enable = true;
  };

  disabledModules = [
    "profiles/all-hardware.nix"
    "profiles/base.nix"
  ];
}
