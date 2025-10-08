defmodule Klix.Repo.Migrations.AddCascades do
  use Ecto.Migration

  def change do
    alter table("images") do
      modify :user_id, references(:users, on_delete: :delete_all), from: references(:users)
    end

    alter table("builds") do
      modify :image_id, references(:images, on_delete: :delete_all), from: references(:images)
    end
  end
end
