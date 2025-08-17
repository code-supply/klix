defmodule Klix.Images do
  def create(attrs) do
    image = %Klix.Images.Image{}
    changeset = Klix.Images.Image.changeset(image, attrs)
    Klix.Repo.insert(changeset)
  end
end
