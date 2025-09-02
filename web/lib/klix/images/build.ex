defmodule Klix.Images.Build do
  use Ecto.Schema

  schema "builds" do
    belongs_to :image, Klix.Images.Image

    timestamps(type: :utc_datetime)
  end

  defmodule Query do
    import Ecto.Query

    alias Klix.Images.Build

    def base do
      from(Build, as: :builds)
    end

    def next(query \\ base()) do
      query
      |> order_by([builds: b], asc: b.inserted_at, asc: b.id)
      |> limit(1)
      |> preload([:image])
    end
  end
end
