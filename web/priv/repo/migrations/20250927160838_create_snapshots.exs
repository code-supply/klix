defmodule Klix.Repo.Migrations.CreateSnapshots do
  use Ecto.Migration

  def change do
    create table("snapshots") do
      add :flake_lock, :text
      add :flake_nix, :text
      add :image_id, references("images")

      timestamps(type: :utc_datetime)
    end
  end
end
