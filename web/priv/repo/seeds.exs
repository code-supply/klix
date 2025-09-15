{:ok, %Klix.Images.Image{builds: [build]}} =
  :image
  |> Klix.Factory.params()
  |> Klix.Images.create()

{:ok, %Klix.Images.Image{builds: [build]}} =
  :image
  |> Klix.Factory.params()
  |> Klix.Images.create()

Klix.Images.build_completed(build)
