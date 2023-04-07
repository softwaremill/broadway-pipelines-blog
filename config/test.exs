import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :broadway_demo, BroadwayDemoWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "taMBbqEXlB5Zu9FTDbjH/lzus0c7pAfYPW4dHuWdqumz/VO4A3QjhCCNw1z0qoia",
  server: false

# In test we don't send emails.
config :broadway_demo, BroadwayDemo.Mailer,
  adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
