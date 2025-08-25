import Config

config :bcrypt_elixir, :log_rounds, 1

config :sql_agent, SqlAgent.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "sql_agent_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

config :sql_agent, SqlAgentWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "L28dVypdtW0vsD3I6jCELuOEmNHXPJdYG64GBL7NSC1Vm7cTgDBp8WvDHwhF7DJF",
  server: false

config :sql_agent, SqlAgent.Mailer, adapter: Swoosh.Adapters.Test

config :swoosh, :api_client, false

config :logger, level: :warning

config :phoenix, :plug_init_mode, :runtime

config :phoenix_live_view,
  enable_expensive_runtime_checks: true
