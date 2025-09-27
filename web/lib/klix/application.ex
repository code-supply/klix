defmodule Klix.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      KlixWeb.Telemetry,
      Klix.Repo,
      {DNSCluster, query: Application.get_env(:klix, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Klix.PubSub},
      KlixWeb.Endpoint,
      {Klix.Builder, build_dir: Application.fetch_env!(:klix, :build_dir)},
      {Klix.Snapshotter, name: Klix.Snapshotter}
    ]

    if Application.fetch_env!(:klix, :run_builder) do
      :telemetry.attach_many(
        :scheduler,
        Klix.Scheduler.events_for(:builder),
        &Klix.Scheduler.handle/4,
        sleep_time: 2000
      )
    end

    :telemetry.attach_many(
      :logger,
      Klix.Builder.telemetry_events(),
      &Klix.Builder.Logger.handle/4,
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
