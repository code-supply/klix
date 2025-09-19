user = Klix.AccountsFixtures.user_fixture()
scope = Klix.Accounts.Scope.for_user(user)

{:ok, _image} =
  Klix.Images.create(scope, Klix.Factory.params(:image))

{:ok, %Klix.Images.Image{builds: [build]}} =
  Klix.Images.create(scope, Klix.Factory.params(:image))

Klix.Images.build_completed(build)
