defmodule Klix.Repo.Migrations.AddImageCascades do
  use Ecto.Migration

  def change do
    alter table("snapshots") do
      modify :image_id, references(:images, on_delete: :delete_all),
        null: false,
        from: references(:images)
    end

    # this was accidentally removed in the previous migration
    alter table("builds") do
      modify :image_id, references(:images, on_delete: :delete_all),
        null: false,
        from: references(:images)
    end
  end
end
