defmodule SqlAgent.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      SqlAgentWeb.Telemetry,
      SqlAgent.Repo,
      SqlAgent.DuckDB,
      {DNSCluster, query: Application.get_env(:sql_agent, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: SqlAgent.PubSub},
      # Oban for background jobs
      {Oban, Application.fetch_env!(:sql_agent, Oban)},
      # Start a worker by calling: SqlAgent.Worker.start_link(arg)
      # {SqlAgent.Worker, arg},
      # Start to serve requests, typically the last entry
      SqlAgentWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SqlAgent.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SqlAgentWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
