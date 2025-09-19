defmodule Klix.Repo.Migrations.AddUserIdToImages do
  use Ecto.Migration

  def change do
    alter table("images") do
      add :user_id, references("users"), null: false
    end
  end
end
