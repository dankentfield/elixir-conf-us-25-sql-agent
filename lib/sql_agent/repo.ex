defmodule SqlAgent.Repo do
  use Ecto.Repo,
    otp_app: :sql_agent,
    adapter: Ecto.Adapters.Postgres
end
