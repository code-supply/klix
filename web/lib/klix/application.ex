defmodule Klix.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      KlixWeb.Telemetry,
      Klix.Repo,
      {DNSCluster, query: Application.get_env(:klix, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Klix.PubSub},
      KlixWeb.Endpoint
    ]

    :telemetry.attach_many(
      :build_telemetry_handler,
      Klix.Builder.telemetry_events(),
      &Klix.Builder.TelemetryHandler.handle/4,
      []
    )

    opts = [strategy: :one_for_one, name: Klix.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    KlixWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
