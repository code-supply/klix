defmodule Klix.Repo.Migrations.AddCompletedAtToImages do
  use Ecto.Migration

  def change do
    alter table("images") do
      add :completed_at, :utc_datetime
    end
  end
end
