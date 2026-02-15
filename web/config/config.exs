# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :klix, :scopes,
  user: [
    default: true,
    module: Klix.Accounts.Scope,
    assign_key: :current_scope,
    access_path: [:user, :id],
    schema_key: :user_id,
    schema_type: :id,
    schema_table: :users,
    test_data_fixture: Klix.AccountsFixtures,
    test_setup_helper: :register_and_log_in_user
  ]

config :klix,
  ecto_repos: [Klix.Repo],
  generators: [timestamp_type: :utc_datetime],
  run_builder: false,
  build_bucket: "klix-dev"

config :klix, Klix.Repo, socket_dir: "/run/postgresql"

# Configures the endpoint
config :klix, KlixWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: KlixWeb.ErrorHTML, json: KlixWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Klix.PubSub,
  live_view: [signing_salt: "PUAjtmCg"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :klix, Klix.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: System.get_env("ESBUILD_VERSION"),
  version_check: false,
  path: System.find_executable("esbuild"),
  klix: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: System.get_env("TAILWIND_VERSION"),
  version_check: false,
  path: System.find_executable("tailwindcss"),
  klix: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :ex_aws,
  http_client: ExAws.Request.Req,
  s3: [
    scheme: "http://",
    host: "localhost",
    port: 9000
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
