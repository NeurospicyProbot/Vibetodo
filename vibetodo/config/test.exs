import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :vibetodo, Vibetodo.Repo,
  database: Path.expand("../vibetodo_test.db", __DIR__),
  pool_size: 5,
  pool: Ecto.Adapters.SQL.Sandbox

# Enable server for Wallaby browser tests
config :vibetodo, VibetodoWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "mV8q176AJePTNhISWOjhBJZN7v/XJiO1ZU/9hQxfH+f87ahhcpDLYWkhQPGybsG5",
  server: true

# Configure Wallaby for browser-based testing
config :wallaby,
  driver: Wallaby.Chrome,
  otp_app: :vibetodo,
  screenshot_dir: "tmp/wallaby_screenshots",
  screenshot_on_failure: true,
  chromedriver: [
    headless: true
  ]

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true

# Disable swoosh API client during tests
config :swoosh, :api_client, false

# Configure test mailer
config :vibetodo, Vibetodo.Mailer, adapter: Swoosh.Adapters.Test
