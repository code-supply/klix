defmodule Klix.Images.Snapshot do
  use Ecto.Schema

  schema "snapshots" do
    field :flake_nix, :string
    field :flake_lock, :string

    belongs_to :image, Klix.Images.Image

    timestamps(type: :utc_datetime)
  end
end
