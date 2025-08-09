{ pkgs }:

with pkgs;

mkShell {
  shellHook = ''
    export ESBUILD_VERSION="${pkgs.esbuild.version}"
    export TAILWIND_VERSION="${pkgs.tailwindcss_4.version}"
  '';

  packages = [
    elixir
    elixir-ls
    esbuild
    inotify-tools
    nixfmt-rfc-style
    python3
    tailwindcss_4
    watchman
  ];
}
