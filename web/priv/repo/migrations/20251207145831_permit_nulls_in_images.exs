defmodule Klix.Repo.Migrations.PermitNullsInImages do
  use Ecto.Migration

  def change do
    alter table("images") do
      modify :hostname, :string, null: true
      modify :timezone, :string, null: true
      modify :klipperscreen_enabled, :boolean, null: true
      modify :plugin_kamp_enabled, :boolean, null: true
      modify :plugin_shaketune_enabled, :boolean, null: true
      modify :plugin_z_calibration_enabled, :boolean, null: true
      modify :public_key, :text, null: true
      modify :klipper_config, :map, null: true
    end
  end
end
