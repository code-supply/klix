defmodule Klix.Images.KlipperConfigTest do
  use Klix.DataCase, async: true

  alias Klix.Images.KlipperConfig

  test "Nix representation is an attribute set" do
    assert %KlipperConfig{
             owner: "code-supply",
             repo: "klix"
           }
           |> Klix.ToNix.to_nix() == """
           {
             type = "github";
             owner = "code-supply";
             repo = "klix";
             flake = false;
           }\
           """
  end

  test "type is required" do
    changeset = KlipperConfig.changeset(%KlipperConfig{}, %{})
    assert changeset.errors[:type] == {"can't be blank", [validation: :required]}
  end

  test "github type requires owner and repo" do
    changeset = KlipperConfig.changeset(%KlipperConfig{}, %{type: :github})
    assert changeset.errors[:owner] == {"can't be blank", [validation: :required]}
    assert changeset.errors[:repo] == {"can't be blank", [validation: :required]}
  end
end
