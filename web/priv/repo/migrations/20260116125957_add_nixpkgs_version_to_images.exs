defmodule Klix.Repo.Migrations.AddNixpkgsVersionToImages do
  use Ecto.Migration

  def change do
    alter table("images") do
      add :nixpkgs_version, :string,
        null: false,
        default: "e6cb50b7edb109d393856d19b797ba6b6e71a4fc"
    end

    alter table("images") do
      modify :nixpkgs_version, :string, default: nil
    end
  end
end
