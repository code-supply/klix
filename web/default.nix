{
  beamPackages,
  callPackages,
  tailwindcss_4,
  esbuild,
  version,
}:

let
  mixNixDeps = callPackages ./deps.nix { };
in
beamPackages.mixRelease {
  pname = "klix";

  inherit mixNixDeps version;

  src = ./.;

  DATABASE_URL = "";
  SECRET_KEY_BASE = "";

  postBuild = ''
    tailwind_path="$(mix do \
      app.config --no-deps-check --no-compile, \
      eval 'Tailwind.bin_path() |> IO.puts()')"
    esbuild_path="$(mix do \
      app.config --no-deps-check --no-compile, \
      eval 'Esbuild.bin_path() |> IO.puts()')"

    ln -s ${mixNixDeps.heroicons} /build/web/deps/heroicons
    ln -s ${tailwindcss_4}/bin/tailwindcss "$tailwind_path"
    ln -s ${esbuild}/bin/esbuild "$esbuild_path"

    mix do \
      app.config --no-deps-check --no-compile, \
      assets.deploy --no-deps-check
  '';
}
