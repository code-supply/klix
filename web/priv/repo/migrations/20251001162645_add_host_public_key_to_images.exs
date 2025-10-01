defmodule Klix.Repo.Migrations.AddHostPublicKeyToImages do
  use Ecto.Migration

  def change do
    alter table("images") do
      add :host_public_key, :binary
    end
  end
end
