defmodule Klix.Repo.Migrations.BigintForBuildByteSize do
  use Ecto.Migration

  def change do
    alter table("builds") do
      modify :byte_size, :bigint
    end
  end
end
