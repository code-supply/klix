defmodule Klix.Images.Build do
  use Ecto.Schema

  schema "builds" do
    belongs_to :image, Klix.Images.Image

    timestamps()
  end

  defmodule Query do
    import Ecto.Query

    alias Klix.Images.Build

    def base do
      from(Build, as: :builds)
    end

    def next(query \\ base()) do
      preload(query, [:image])
    end
  end
end
