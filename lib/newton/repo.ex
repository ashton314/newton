defmodule Newton.Repo do
  use Ecto.Repo,
    otp_app: :newton,
    adapter: Ecto.Adapters.Postgres
end
