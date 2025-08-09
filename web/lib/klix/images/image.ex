defmodule Klix.Images.Image do
  use Ecto.Schema

  schema "images" do
    field :hostname, :string
  end
end
