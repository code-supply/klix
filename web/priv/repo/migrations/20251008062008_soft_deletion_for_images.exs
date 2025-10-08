defmodule Klix.Repo.Migrations.SoftDeletionForImages do
  use Ecto.Migration

  def change do
    alter table("images") do
      add :deleted_at, :utc_datetime
    end
  end
end
