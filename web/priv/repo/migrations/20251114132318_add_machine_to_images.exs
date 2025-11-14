defmodule Klix.Repo.Migrations.AddMachineToImages do
  use Ecto.Migration

  def change do
    alter table("images") do
      add :machine, :string, default: "raspberry_pi_4", null: false
    end
  end
end
