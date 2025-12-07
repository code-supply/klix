defmodule Klix.Repo.Migrations.AddUnfinishedImageIdToUsers do
  use Ecto.Migration

  def change do
    alter table("users") do
      add :unfinished_image_id, references("images")
    end
  end
end
