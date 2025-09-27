defmodule Klix.SnapshottingTest do
  use Klix.DataCase, async: true

  setup do: %{scope: user_fixture() |> Scope.for_user()}

  test "writes a flake.nix and flake.lock", %{scope: scope} do
    {:ok, image} =
      Images.create(
        scope,
        Klix.Factory.params(:image,
          klipper_config: [
            type: :github,
            owner: "code-supply",
            repo: "code-supply",
            path: "boxes/ketchup-king/klipper"
          ]
        )
      )

    {:ok, snapshot, _tarball} = Images.snapshot(image)

    assert snapshot.flake_nix == Images.to_flake(image)
    assert snapshot.flake_lock =~ ~s({\n  "nodes": {)
  end

  test "returns error if repo can't be found", %{scope: scope} do
    {:ok, image} =
      Images.create(
        scope,
        Klix.Factory.params(:image,
          klipper_config: [
            type: :github,
            owner: "code-supply",
            repo: "not-my-repo",
            path: "some/bogus/path"
          ]
        )
      )

    assert {:error, :error_updating_lock_file} = Images.snapshot(image)
  end
end
