defmodule Klix.Repo.Migrations.AddCurrentVersionsToImages do
  use Ecto.Migration

  def change do
    alter table("images") do
      add :current_versions, :map
      add :current_versions_updated_at, :utc_datetime
    end
  end
end
