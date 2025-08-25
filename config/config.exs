import Config

config :sql_agent, :scopes,
  user: [
    default: true,
    module: SqlAgent.Accounts.Scope,
    assign_key: :current_scope,
    access_path: [:user, :id],
    schema_key: :user_id,
    schema_type: :id,
    schema_table: :users,
    test_data_fixture: SqlAgent.AccountsFixtures,
    test_setup_helper: :register_and_log_in_user
  ]

config :sql_agent,
  ecto_repos: [SqlAgent.Repo],
  generators: [timestamp_type: :utc_datetime]

config :sql_agent, Oban,
  engine: Oban.Engines.Basic,
  queues: [default: 10, messages: 5],
  repo: SqlAgent.Repo

config :sql_agent, SqlAgentWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: SqlAgentWeb.ErrorHTML, json: SqlAgentWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: SqlAgent.PubSub,
  live_view: [signing_salt: "MJtiw1BC"]

config :sql_agent, SqlAgent.Mailer, adapter: Swoosh.Adapters.Local

config :esbuild,
  version: "0.25.4",
  sql_agent: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

config :tailwind,
  version: "4.1.7",
  sql_agent: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
