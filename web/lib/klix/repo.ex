defmodule Klix.Repo do
  use Ecto.Repo,
    otp_app: :klix,
    adapter: Ecto.Adapters.Postgres
end
