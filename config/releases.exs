import Config

config :newton, Newton.Repo,
  # ssl: true,
  username: "newton",
  password: System.get_env("POSTGRES_PASSWORD") || raise("No db password set in env"),
  database: "newton_prod",
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

secret_key_base =
  System.get_env("SECRET_KEY_BASE") ||
    raise """
    environment variable SECRET_KEY_BASE is missing.
    """

config :newton, NewtonWeb.Endpoint,
  http: [
    port: String.to_integer(System.get_env("PORT") || "4000"),
    transport_options: [socket_opts: [:inet6]]
  ],
  secret_key_base: secret_key_base,
  force_ssl: [rewrite_on: [:x_forwarded_proto], hsts: true],
  url: [host: System.get_env("APP_HOSTNAME"), port: 443],
  https: [
    :inet6,
    port: 443,
    cipher_suite: :strong,
    keyfile: System.get_env("SSL_KEY_PATH"),
    certfile: System.get_env("SSL_CERT_PATH")
  ],
  cache_static_manifest: "priv/static/cache_manifest.json"

# ## Using releases (Elixir v1.9+)
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start each relevant endpoint:
#
config :newton, NewtonWeb.Endpoint, server: true
#
# Then you can assemble a release by calling `mix release`.
# See `mix help release` for more information.

config :newton, latex_cache: "/tmp/latex_renderer/cache"
