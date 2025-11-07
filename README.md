# PeekAppSDK

This is a library to help with authenticating requests to and from PeekPro when
writing apps.

## Configuration

### Basic Configuration

```elixir
config :peek_app_sdk,
  peek_app_secret: "APP_SECRET",
  peek_app_id: "APP_ID",
  peek_api_base_url: "https://apps.peekapis.com/",
  peek_api_key: "API_KEY"
```

### Multiple Application Configurations

PeekAppSDK supports multiple configurations, allowing different applications to use their own credentials through a centralized configuration structure:

```elixir
# Default configuration
config :peek_app_sdk,
  peek_app_secret: "DEFAULT_SECRET",
  peek_app_id: "DEFAULT_APP_ID",
  peek_api_base_url: "https://apps.peekapis.com/",
  peek_api_key: "DEFAULT_API_KEY",
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

Note that `peek_api_base_url` and `peek_api_key` are always taken from the default configuration.

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
const path = require('path')

const peekSDKConfig = require('../../../deps/peek_app_sdk/assets/tailwind.config.js')
const sdkConfig = peekSDKConfig({
  heroiconsPath: path.join(__dirname, '../deps/heroicons/optimized')
})

module.exports = {
  content: [
    './js/**/*.js',
    '../lib/project_name_web.ex',
    '../lib/project_name_web/**/*.*ex',
    '../lib/project_name_web/controllers/**/*.html.heex',
    // add one of the following line, adjust to your needs
    '../deps/peek_app_sdk/lib/peek_app_sdk/**/*.*ex', // this is if you are in a single elixir app
    '../../../deps/peek_app_sdk/lib/peek_app_sdk/**/*.*ex' // this is if you are in an umbrella app
  ],
  theme: {
    extend: {
      ...sdkConfig.theme.extend
    }
  },
  plugins: [...sdkConfig.plugins]
}
```

This will ensure your application includes all the necessary styles for PeekAppSDK components.

## JavaScript Integration

To use PeekAppSDK's JavaScript hooks in your Phoenix LiveView application, add this to your `assets/js/app.js` file:

```javascript
// Import PeekAppSDK hooks
import PeekAppSDKHooks from "peek_app_sdk"

// If you don't have any other hooks:
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: PeekAppSDKHooks
})

// If you have other hooks, merge them:
let Hooks = {
  ...PeekAppSDKHooks,
  // your other hooks here
}

let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: Hooks
})
```

The import works because PeekAppSDK includes a `package.json` file that tells Node.js where to find the JavaScript hooks.

## Odyssey UI Components Integration

PeekAppSDK includes Odyssey UI components that provide rich interactive elements for your Phoenix LiveView applications. To integrate these components:

### 1. Add the Odyssey UI Components Import

In your Phoenix web module (e.g., `lib/your_app_web.ex`), add the import to both the `html` and `live_view` functions:

```elixir
def html do
  quote do
    use Phoenix.Component
    import PeekAppSDK.UI.Odyssey  # Add this line
    import YourAppWeb.CoreComponents
    # ... other imports
  end
end

def live_view do
  quote do
    use Phoenix.LiveView,
      layout: {YourAppWeb.Layouts, :app}

    import PeekAppSDK.UI.Odyssey  # Add this line
    import YourAppWeb.CoreComponents
    # ... other imports
  end
end
```

### 2. Include Odyssey Web Components JavaScript

In your `assets/js/app.js` file, add the Odyssey web components:

```javascript
// Import Odyssey web components (required for UI components to work)
require('../../deps/peek_app_sdk/priv/static/odyssey_web_components.min.js');

// Import PeekAppSDK hooks
import peekAppSDK from "peek_app_sdk"

const Hooks = {
  ...peekAppSDK
}

let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: Hooks
})
```

### 3. Include Odyssey Styles

In your `assets/css/app.css` file, add the Odyssey assets to your Tailwind sources:

```css
@import "tailwindcss/base";
@import "tailwindcss/components";
@import "tailwindcss/utilities";

@source "../css";
@source "../js";
@source "../../lib/your_app_web";
@import "../../deps/peek_app_sdk/assets/odyssey/odyssey_web_components.css";
@source "../../deps/peek_app_sdk/assets";  /* Add this line */
```

### 4. Using Odyssey Components

Once integrated, you can use Odyssey components in your LiveView templates:

```heex
<.form for={@form} phx-change="activity_changed">
  <.odyssey_activity_picker
    install_id={@app_installation_id}
    field={@form[:activity_id]}
  />
</.form>
```

The activity picker component will automatically handle activity selection and update the form field when activities are chosen.

### Updating Odyssey Components

Simply update odyssey_web_components.js and odyssey_web_components.css in your assets folder and run `mix assets.deploy` and get merged into main. When upstream apps run a mix deps.update peek_app_sdk they'll get the updated odyssey assets.

# PeekAppSDK Metrics

This document describes how to use the metrics functionality in the PeekAppSDK.

## Basic Usage

The PeekAppSDK provides a simple function for tracking metrics:

- `track/2` - Track any event with flexible payload

## Using `track`

The `track/2` function provides a simple and flexible way to track events with any fields you need. It takes an event ID and a map of fields, and sends them directly to the metrics service without any validation or transformation.

### Parameters

- `event_id` - The ID of the event to track (e.g., "app.install", "user.login")
- `payload` - A map containing any fields you want to include in the event

### Basic Example

```elixir
PeekAppSDK.Metrics.track("app.install", %{
  anonymousId: "partner-123",
  level: "info"
})
```

### Full Example with Common Fields

```elixir
PeekAppSDK.Metrics.track("app.install", %{
  # Required
  anonymousId: "partner-123",
  level: "info",

  # Optional, useful for additional metrics features
  usageDisplay: "New App Installs",
  usageDetails: "Bob's Surf",
  postMessage: "Bob's Surf installed",

  # Optional, useful for data analysis
  userId: "user-456",
  idempotencyKey: "unique-key-789",

  context: %{
    channel: "web",
    userAgent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)",
    sessionId: "session-123",
    timezone: "America/Los_Angeles",
    ip: "192.168.1.1",
    page: "/install",
    screen: %{
      height: 1080,
      width: 1920
    }
  },

  customFields: %{
    "partnerId" => "partner-123",
    "partnerName" => "Bob's Surf",
    "partnerIsTest" => false
  }
})
```

## Flexibility

The `track/2` function is designed to be as flexible as possible. You can include any fields you need in the payload, and they will be sent directly to the metrics service. This allows you to track custom events with any data structure you need.

```elixir
PeekAppSDK.Metrics.track("custom.event", %{
  anonymousId: "user-123",
  someCustomField: "custom value",
  nestedData: %{
    key1: "value1",
    key2: "value2"
  },
  arrayData: [1, 2, 3]
})
```

## Common Field Names

While the `track/2` function doesn't enforce any specific field names, here are some common field names that are used in the metrics service:

| Field Name       | Description                                              |
| ---------------- | -------------------------------------------------------- |
| `anonymousId`    | Identifier for the event (usually partner ID or user ID) |
| `level`          | Event level (e.g., "info", "error")                      |
| `usageDisplay`   | Display name for usage metrics                           |
| `usageDetails`   | Details for usage metrics                                |
| `postMessage`    | Message to post with the event                           |
| `userId`         | User ID associated with the event                        |
| `idempotencyKey` | Key to prevent duplicate events                          |
| `context`        | Contextual information about the event                   |
| `customFields`   | Custom fields to include with the event                  |

## Common Event Types

Here are some common event types that are used in the metrics service:

- `app.install` - App installation
- `app.uninstall` - App uninstallation
- `user.login` - User login
- `user.logout` - User logout
- `app.error` - Application error
