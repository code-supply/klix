defmodule Klix.Images.Build do
  use Ecto.Schema

  schema "builds" do
    belongs_to :image, Klix.Images.Image

    timestamps()
  end
end
