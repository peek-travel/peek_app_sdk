# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  odyssey_hooks: [
    args:
      ~w(js/odyssey.js --bundle --target=es2022 --format=cjs --minify --outfile=../priv/static/odyssey_hooks.min.js),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ],
  odyssey_web_components: [
    args:
      ~w(odyssey/odyssey_web_components.js --bundle --target=es2022 --minify --outfile=../priv/static/odyssey_web_components.min.js),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
