defmodule Klix.VersionRetrievalTest do
  use Klix.DataCase, async: true

  test "can get versions that have been previously stored as an ordered list" do
    scope = Scope.for_user(user_fixture())

    {:ok, %{builds: [build]} = image} =
      Images.create(
        scope,
        Factory.params(
          :image,
          klipperscreen_enabled: false,
          plugin_z_calibration_enabled: false
        )
      )

    {:ok, build} =
      Klix.Images.store_versions(
        build,
        %{
          "cage" => "0.2.0",
          "fluidd" => "1.34.3",
          "kamp" => "b0dad8ec9ee31cb644b94e39d4b8a8fb9d6c9ba0",
          "klipper" => "0.13.0-unstable-2025-08-15",
          "klipperscreen" => "5ba4a1ff134ac1eba236043b8ec316c2298846e5",
          "linux" => "6.12.34-stable_20250702",
          "moonraker" => "0.9.3-unstable-2025-08-01",
          "nginx" => "1.28.0",
          "nixos-hardware" => "db030f62a449568345372bd62ed8c5be4824fa49",
          "nixpkgs" => "e6cb50b7edb109d393856d19b797ba6b6e71a4fc",
          "plymouth" => "24.004.60",
          "shaketune" => "c8ef451ec4153af492193ac31ed7eea6a52dbe4e",
          "wayland" => "1.24.0",
          "z_calibration" => "487056ac07e7df082ea0b9acc7365b4a9874889e"
        }
      )

    versions = Images.versions(image, build)

    assert {:cage, "0.2.0"} in versions
    assert {:linux, "6.12.34"} in versions
    assert {:kamp, "b0dad8e"} in versions
    refute Keyword.has_key?(versions, :id)
    refute Keyword.has_key?(versions, :z_calibration)
    refute Keyword.has_key?(versions, :klipperscreen)
  end

  # works because we have the same output in Klix's flake as each printer's flake
  test "can retrieve and store the versions of interesting dependencies" do
    scope = Scope.for_user(user_fixture())
    {:ok, versions} = Images.retrieve_versions(__DIR__ <> "/../..")
    {:ok, image} = Images.create(scope, Factory.params(:image))
    [build] = image.builds
    {:ok, build} = Klix.Images.store_versions(build, versions)

    for attr <- Images.Versions.permitted_attrs() do
      assert Map.get(build.versions, attr) =~ ~r/\d/, "#{attr} not set"
    end
  end

  test "it's an error when there's no flake" do
    dir = "/tmp/some/made/up/place"
    File.mkdir_p!(dir)

    assert Klix.Images.retrieve_versions(dir) ==
             {
               :error,
               :nix_eval_failed,
               1
             }
  end
end
