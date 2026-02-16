{
  awscli2,
  beamPackages,
  esbuild,
  inotify-tools,
  mkShell,
  nixfmt,
  python3,
  stdenv,
  tailwindcss_4,
  watchman,
  writeShellApplication,
}:

let
  system = stdenv.hostPlatform.system;
  rustfs =
    (builtins.getFlake "github:rustfs/rustfs/f4028a46412434d78fa0c2a30e041f5e62f7d2aa")
    .packages.${system}.default;

  s3dev = writeShellApplication {
    name = "s3dev";
    text = ''
      mkdir -p /tmp/rustfs-buckets/klix-dev
      ${rustfs}/bin/rustfs /tmp/rustfs-buckets
    '';
  };
in
mkShell {
  shellHook = ''
    export ERL_AFLAGS="-kernel shell_history enabled"
    export ESBUILD_VERSION="${esbuild.version}"
    export TAILWIND_VERSION="${tailwindcss_4.version}"
  '';

  packages = [
    awscli2
    beamPackages.elixir
    beamPackages.elixir-ls
    esbuild
    inotify-tools
    nixfmt
    python3
    rustfs
    s3dev
    tailwindcss_4
    watchman
  ];
}
