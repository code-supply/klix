defmodule Klix.Repo.Migrations.AddErrorToBuilds do
  use Ecto.Migration

  def change do
    alter table("builds") do
      add :error, :text, null: true
    end
  end
end
