defmodule Klix.Repo.Migrations.AddImageUriIds do
  use Ecto.Migration

  def change do
    alter table("images") do
      add :uri_id, :uuid, null: false
    end

    create unique_index("images", [:uri_id])
  end
end
