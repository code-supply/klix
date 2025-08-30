defmodule Klix.Repo.Migrations.CreateImages do
  use Ecto.Migration

  def change do
    create table("images") do
      add :hostname, :string, null: false
      add :timezone, :string, null: false
      add :klipperscreen_enabled, :boolean, null: false
      add :plugin_kamp_enabled, :boolean, null: false
      add :plugin_shaketune_enabled, :boolean, null: false
      add :plugin_z_calibration_enabled, :boolean, null: false
      add :public_key, :text, null: false

      timestamps(type: :utc_datetime)
    end
  end
end
