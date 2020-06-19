# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :newton,
  ecto_repos: [Newton.Repo]

# Configures the endpoint
config :newton, NewtonWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "ZakiakVGSKPzjrw7ibO/qYO2uFvhlZPFWWaa6PPMUKtd0akJLs76Oh+xZJqbJ9On",
  render_errors: [view: NewtonWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Newton.PubSub,
  live_view: [signing_salt: "67q+lGQv"]

config :newton, :generators,
  migration: true,
  binary_id: true,
  sample_binary_id: "11111111-1111-1111-1111-111111111111"

# LatexRenderer configuration
config :newton,
  latex_cache: "priv/static/images/latex_renderer/cache",
  latex_program: "xelatex"

# Garbage collector configuration---all time in seconds
config :newton, Newton.GarbageCollector,
  collect_every: 5 * 60,
  max_age: 5 * 60

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
