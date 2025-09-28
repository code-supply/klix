defmodule Klix.Repo.Migrations.SnapshotImageIdNonNull do
  use Ecto.Migration

  def change do
    alter table("snapshots") do
      modify :image_id, :integer, null: false
    end
  end
end
