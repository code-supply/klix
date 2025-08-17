defmodule Klix.Images do
  def find!(id) do
    Klix.Repo.get!(Klix.Images.Image, id)
  end

  def create(attrs) do
    image = %Klix.Images.Image{}
    changeset = Klix.Images.Image.changeset(image, attrs)
    Klix.Repo.insert(changeset)
  end
end
