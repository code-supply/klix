defmodule Klix.Repo.Migrations.AddCompletedAtToBuilds do
  use Ecto.Migration

  def change do
    alter table("builds") do
      add :completed_at, :utc_datetime
    end
  end
end
