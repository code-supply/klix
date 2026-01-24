user = Klix.AccountsFixtures.user_fixture(email: "me@andrewbruce.net")
scope = Klix.Accounts.Scope.for_user(user)

{:ok, _image} =
  Klix.Images.create(scope, Klix.Factory.params(:image, hostname: "unfinished"))

{:ok, %Klix.Images.Image{builds: [finished_build]} = image} =
  Klix.Images.create(
    scope,
    Klix.Factory.params(:image, hostname: "finished", plugin_z_calibration_enabled: false)
  )

{:ok, %Klix.Images.Image{builds: [failed_build]} = failed_image} =
  Klix.Images.create(
    scope,
    Klix.Factory.params(:image, hostname: "error")
  )

build_start =
  DateTime.utc_now(:second)
  |> DateTime.add(-4000, :second, Tzdata.TimeZoneDatabase)

{:ok, failed_build} =
  failed_build
  |> Ecto.Changeset.change(inserted_at: build_start, byte_size: 99_999_999)
  |> Klix.Repo.update()

{:ok, _failed_build} = Klix.Images.build_failed(failed_build, "bad stuff happened!")

{:ok, finished_build} =
  finished_build
  |> Ecto.Changeset.change(inserted_at: build_start, byte_size: 99_999_999)
  |> Klix.Repo.update()

{:ok, finished_build} =
  Klix.Images.store_versions(
    finished_build,
    %{
      "cage" => "0.2.0",
      "fluidd" => "1.34.3",
      "kamp" => "b0dad8ec9ee31cb644b94e39d4b8a8fb9d6c9ba0",
      "klipper" => "0.13.0-unstable-2025-08-15",
      "klipperscreen" => "5ba4a1ff134ac1eba236043b8ec316c2298846e5",
      "klix" => "dev",
      "linux" => "6.12.34-stable_20250702",
      "moonraker" => "0.9.3-unstable-2025-08-01",
      "nginx" => "1.28.0",
      "nixos-raspberrypi" => "db030f62a449568345372bd62ed8c5be4824fa49",
      "nixpkgs" => "e6cb50b7edb109d393856d19b797ba6b6e71a4fc",
      "plymouth" => "24.004.60",
      "shaketune" => "c8ef451ec4153af492193ac31ed7eea6a52dbe4e",
      "wayland" => "1.24.0",
      "z_calibration" => "487056ac07e7df082ea0b9acc7365b4a9874889e"
    }
  )

image_scope = Klix.Accounts.Scope.for_image(image)

{:ok, _image} =
  Klix.Images.store_versions(
    image_scope,
    %{
      "cage" => "0.4.0",
      "fluidd" => "1.35.0",
      "kamp" => "b0dad8ec9ee31cb644b94e39d4b8a8fb9d6c9ba0",
      "klipper" => "0.13.0-unstable-2025-08-15",
      "klipperscreen" => "5ba4a1ff134ac1eba236043b8ec316c2298846e5",
      "klix" => "dev",
      "linux" => "6.12.34-stable_20250702",
      "moonraker" => "0.9.3-unstable-2025-08-01",
      "nginx" => "1.28.0",
      "nixos-raspberrypi" => "db030f62a449568345372bd62ed8c5be4824fa49",
      "nixpkgs" => "e6cb50b7edb109d393856d19b797ba6b6e71a4fc",
      "plymouth" => "24.004.60",
      "shaketune" => "c8ef451ec4153af492193ac31ed7eea6a52dbe4e",
      "wayland" => "1.24.0",
      "z_calibration" => "487056ac07e7df082ea0b9acc7365b4a9874889e"
    }
  )

Klix.Images.build_completed(finished_build)
