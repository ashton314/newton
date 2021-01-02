defmodule Newton.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  @app :newton

  use Application

  def start(_type, _args) do
    children =
      if Application.get_env(@app, :minimal) do
        [
          # Start the Ecto repository
          Newton.Repo,
          {DynamicSupervisor, strategy: :one_for_one, name: LatexRendering.Supervisor}
        ]
      else
        [
          # Start the Ecto repository
          Newton.Repo,
          # Start the Telemetry supervisor
          NewtonWeb.Telemetry,
          # Start the PubSub system
          {Phoenix.PubSub, name: Newton.PubSub},
          # Start the Endpoint (http/https)
          NewtonWeb.Endpoint,
          Newton.GarbageCollector,
          # Start a worker by calling: Newton.Worker.start_link(arg)
          # {Newton.Worker, arg}
          {DynamicSupervisor, strategy: :one_for_one, name: LatexRendering.Supervisor}
        ]
      end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Newton.Supervisor]
    result = Supervisor.start_link(children, opts)

    Newton.Release.migrate_no_load()

    result
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    NewtonWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
