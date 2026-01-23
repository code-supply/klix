defmodule Klix.Repo.Migrations.BuildsMustHaveImages do
  use Ecto.Migration

  def change do
    drop constraint("builds", "builds_image_id_fkey")

    alter table("builds") do
      modify :image_id, references("images"), null: false
    end
  end
end
