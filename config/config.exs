# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Configure esbuild
config :esbuild,
  version: "0.17.11",
  demo: [
    args: ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind
config :tailwind,
  version: "3.3.2",
  demo: [
    args: ~w(
      --config=tailwind.demo.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configure the Phoenix endpoint for the demo
config :peek_app_sdk, PeekAppSDK.Demo.Endpoint,
  url: [host: "localhost"],
  adapter: Phoenix.Endpoint.Cowboy2Adapter,
  render_errors: [formats: [html: PeekAppSDK.Demo.ErrorHTML], layout: false],
  pubsub_server: PeekAppSDK.PubSub,
  live_view: [signing_salt: "Ij9Nt9Oe"],
  http: [ip: {127, 0, 0, 1}, port: 4000],
  server: true,
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base:
    "Ij9Nt9OeIj9Nt9OeIj9Nt9OeIj9Nt9OeIj9Nt9OeIj9Nt9OeIj9Nt9OeIj9Nt9OeIj9Nt9OeIj9Nt9Oe"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
