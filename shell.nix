{ pkgs }:

with pkgs;

mkShell {
  packages = [
    elixir
    elixir-ls
    inotify-tools
    nixfmt-rfc-style
    python3
  ];
}
