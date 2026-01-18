defmodule Klix.Repo.Migrations.DontRequireUserIdOnImages do
  use Ecto.Migration

  def change do
    drop constraint("images", "images_user_id_fkey")

    alter table("images") do
      modify :user_id, references("users"), null: true
    end
  end
end
