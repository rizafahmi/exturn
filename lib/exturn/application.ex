defmodule Exturn.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ExturnWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:exturn, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Exturn.PubSub},
      ExturnWeb.Presence,
      # Start a worker by calling: Exturn.Worker.start_link(arg)
      # {Exturn.Worker, arg},
      # Start to serve requests, typically the last entry
      ExturnWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Exturn.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ExturnWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
