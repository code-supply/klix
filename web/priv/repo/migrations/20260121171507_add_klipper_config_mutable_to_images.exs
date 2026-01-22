defmodule Klix.Repo.Migrations.AddKlipperConfigMutableToImages do
  use Ecto.Migration

  def change do
    alter table("images") do
      add :klipper_config_mutable, :boolean, default: true, null: false
    end
  end
end
