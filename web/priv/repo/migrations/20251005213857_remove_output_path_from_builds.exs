defmodule Klix.Repo.Migrations.RemoveOutputPathFromBuilds do
  use Ecto.Migration

  def change do
    alter table("builds") do
      remove :output_path
    end
  end
end
