defmodule Klix.Repo.Migrations.AddVersionsToBuild do
  use Ecto.Migration

  def change do
    alter table("builds") do
      add :versions, :map
    end
  end
end
