user = Klix.AccountsFixtures.user_fixture(email: "me@andrewbruce.net")
scope = Klix.Accounts.Scope.for_user(user)

{:ok, _image} =
  Klix.Images.create(scope, Klix.Factory.params(:image))

{:ok, %Klix.Images.Image{builds: [build]}} =
  Klix.Images.create(scope, Klix.Factory.params(:image))

build_start =
  DateTime.utc_now(:second)
  |> DateTime.add(-4000, :second, Tzdata.TimeZoneDatabase)

{:ok, build} =
  build
  |> Ecto.Changeset.change(inserted_at: build_start)
  |> Klix.Repo.update()

Klix.Images.build_completed(build)
