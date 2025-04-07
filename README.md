# PeekAppSDK

This is a library to help with authenticating requests to and from PeekPro when
writing apps.

## Configuration

### Basic Configuration

```elixir
config :peek_app_sdk,
  peek_app_secret: "APP_SECRET",
  peek_app_id: "APP_ID",
  peek_api_url: "https://apps.peekapis.com/backoffice-gql",
  peek_app_key: "APP_KEY"
```

### Multiple Application Configurations

PeekAppSDK supports multiple configurations, allowing different applications to use their own credentials through a centralized configuration structure:

```elixir
# Default configuration
config :peek_app_sdk,
  peek_app_secret: "DEFAULT_SECRET",
  peek_app_id: "DEFAULT_APP_ID",
  peek_api_url: "https://apps.peekapis.com/backoffice-gql",
  peek_app_key: "DEFAULT_APP_KEY",
  # Centralized app configurations
  apps: [
    semnox: [peek_app_id: "SEMNOX_APP_ID", peek_app_secret: "SEMNOX_APP_SECRET"],
    another_app: [peek_app_id: "ANOTHER_APP_ID", peek_app_secret: "ANOTHER_APP_SECRET"]
  ]
```

Then use the application identifier when calling PeekAppSDK functions:

```elixir
# Using default configuration
PeekAppSDK.query_peek_pro("install_id", "query { test }")

# Using application-specific configuration
PeekAppSDK.query_peek_pro("install_id", "query { test }", %{}, :semnox)
```

Note that `peek_api_url` and `peek_app_key` are always taken from the default configuration.

## Some setup tips:

- `import PeekAppSDK.Plugs.PeekAuth` in router
- `plug :set_peek_install_id` can be used for routes that need to verify a peek
  request. This will set a `peek_install_id` prop in the `assigns` of the `conn`
- `live_session :some_live_view_session_scope, on_mount: {PeekAppSDK.Plugs.PeekAuth, :set_install_id_for_live_view}` will set the
  `peek_install_id` on the Socket for live view usage.
