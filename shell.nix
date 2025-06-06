{ pkgs }:

with pkgs;

mkShell {
  packages = [
    python3
    nixfmt-rfc-style
  ];
}
