defmodule Klix.VersionRetrievalTest do
  use Klix.DataCase, async: true

  # works because we have the same output in Klix's flake as each printer's flake
  test "can retrieve and store the versions of interesting dependencies" do
    scope = Scope.for_user(user_fixture())
    {:ok, versions} = Klix.Images.retrieve_versions(__DIR__ <> "/../..")
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
