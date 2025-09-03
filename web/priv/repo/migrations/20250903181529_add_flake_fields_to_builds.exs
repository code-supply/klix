defmodule Klix.Repo.Migrations.AddFlakeFieldsToBuilds do
  use Ecto.Migration

  def change do
    alter table("builds") do
      add :flake_lock, :text
      add :flake_nix, :text
      add :output_path, :text
    end
  end
end
