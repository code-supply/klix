defmodule Klix.Repo.Migrations.AddKlixVersionToImages do
  use Ecto.Migration

  def change do
    alter table("images") do
      add :klix_version, :string, default: "main", null: false
    end

    alter table("images") do
      modify :klix_version, :string, default: nil
    end
  end
end
