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
    project_name: [peek_app_id: "project_name_APP_ID", peek_app_secret: "project_name_APP_SECRET"],
    another_app: [peek_app_id: "ANOTHER_APP_ID", peek_app_secret: "ANOTHER_APP_SECRET"]
  ]
```

Then use the application identifier when calling PeekAppSDK functions:

```elixir
# Using default configuration
PeekAppSDK.query_peek_pro("install_id", "query { test }")

# Using application-specific configuration
PeekAppSDK.query_peek_pro("install_id", "query { test }", %{}, :project_name)
```

Note that `peek_api_url` and `peek_app_key` are always taken from the default configuration.

## Some setup tips:

- `import PeekAppSDK.Plugs.PeekAuth` in router
- `plug :set_peek_install_id` can be used for routes that need to verify a peek
  request. This will set a `peek_install_id` prop in the `assigns` of the `conn`
- `live_session :some_live_view_session_scope, on_mount: {PeekAppSDK.Plugs.PeekAuth, :set_install_id_for_live_view}` will set the
  `peek_install_id` on the Socket for live view usage.

## Tailwind CSS Configuration

To use PeekAppSDK's Tailwind styles in your application:

1. make sure hero-icons is in your deps:

```elixir
  {:heroicons, github: "tailwindlabs/heroicons", tag: "v2.1.1", sparse: "optimized", app: false, compile: false, depth: 1}
```

2. In your application's `assets/tailwind.config.js`, extend the configuration:

```javascript
// Import PeekAppSDK's Tailwind config
const path = require('path');

const peekSDKConfig = require('../../../deps/peek_app_sdk/assets/tailwind.config.js');
const sdkConfig = peekSDKConfig({
  heroiconsPath: path.join(__dirname, '../deps/heroicons/optimized'),
});

module.exports = {
  content: [
    './js/**/*.js',
    '../lib/project_name_web.ex',
    '../lib/project_name_web/**/*.*ex',
    '../lib/project_name_web/controllers/**/*.html.heex',
    // add one of the following line, adjust to your needs
    '../deps/peek_app_sdk/lib/peek_app_sdk/**/*.*ex', // this is if you are in a single elixir app
    '../../../deps/peek_app_sdk/lib/peek_app_sdk/**/*.*ex', // this is if you are in an umbrella app
  ],
  theme: {
    extend: {
      ...sdkConfig.theme.extend,
    },
  },
  plugins: [...sdkConfig.plugins],
};
```

This will ensure your application includes all the necessary styles for PeekAppSDK components.
