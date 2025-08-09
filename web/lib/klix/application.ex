defmodule Klix.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      KlixWeb.Telemetry,
      Klix.Repo,
      {DNSCluster, query: Application.get_env(:klix, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Klix.PubSub},
      # Start a worker by calling: Klix.Worker.start_link(arg)
      # {Klix.Worker, arg},
      # Start to serve requests, typically the last entry
      KlixWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
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
