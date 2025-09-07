defmodule Klix.Repo.Migrations.AddKlipperConfigToImages do
  use Ecto.Migration

  def change do
    alter table(:images) do
      add :klipper_config, :map, null: false
    end
  end
end
