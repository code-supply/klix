user = Klix.AccountsFixtures.user_fixture(email: "me@andrewbruce.net")
scope = Klix.Accounts.Scope.for_user(user)

{:ok, _image} =
  Klix.Images.create(scope, Klix.Factory.params(:image, hostname: "unfinished"))

{:ok, %Klix.Images.Image{builds: [finished_build]}} =
  Klix.Images.create(scope, Klix.Factory.params(:image, hostname: "finished"))

build_start =
  DateTime.utc_now(:second)
  |> DateTime.add(-4000, :second, Tzdata.TimeZoneDatabase)

{:ok, finished_build} =
  finished_build
  |> Ecto.Changeset.change(inserted_at: build_start)
  |> Klix.Repo.update()

{:ok, finished_build} =
  Klix.Images.store_versions(
    finished_build,
    Klix.Images.Versions.permitted_attrs()
    |> Map.from_keys("1.2.3")
  )

Klix.Images.build_completed(finished_build)
