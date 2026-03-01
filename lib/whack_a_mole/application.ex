defmodule WhackAMole.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      WhackAMoleWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:whack_a_mole, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: WhackAMole.PubSub},
      # Start a worker by calling: WhackAMole.Worker.start_link(arg)
      # {WhackAMole.Worker, arg},
      # Start to serve requests, typically the last entry
      WhackAMoleWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: WhackAMole.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    WhackAMoleWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
