{ pkgs }:

with pkgs;

mkShell {
  packages = [
    elixir
    elixir-ls
    nixfmt-rfc-style
    python3
  ];
}
