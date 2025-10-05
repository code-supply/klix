defmodule Klix.Repo.Migrations.AddByteSizeToBuilds do
  use Ecto.Migration

  def change do
    alter table("builds") do
      add :byte_size, :integer
    end
  end
end
