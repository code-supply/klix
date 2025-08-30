defmodule Klix.Repo.Migrations.CreateBuilds do
  use Ecto.Migration

  def change do
    create table("builds") do
      add :finished_at, :datetime, null: true
      add :image_id, references("images")
      timestamps(type: :utc_datetime)
    end
  end
end
