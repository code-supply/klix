{
  beamPackages,
  esbuild,
  inotify-tools,
  mkShell,
  nixfmt-rfc-style,
  python3,
  tailwindcss_4,
  watchman,
}:

mkShell {
  shellHook = ''
    export ERL_AFLAGS="-kernel shell_history enabled"
    export ESBUILD_VERSION="${esbuild.version}"
    export TAILWIND_VERSION="${tailwindcss_4.version}"
  '';

  packages = [
    beamPackages.elixir
    beamPackages.elixir-ls
    esbuild
    inotify-tools
    nixfmt-rfc-style
    python3
    tailwindcss_4
    watchman
  ];
}
