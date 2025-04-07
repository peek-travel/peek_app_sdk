import Config

# Configure peek_app_sdk for tests
config :peek_app_sdk,
  peek_app_secret: "test_secret",
  peek_app_id: "test_app_id",
  peek_api_url: "https://apps.peekapis.com/backoffice-gql",
  peek_app_key: "test_app_key",
  # Centralized configuration structure
  apps: [
    semnox: [
      peek_app_id: "semnox_app_id",
      peek_app_key: "semnox_app_key",
      peek_app_secret: "semnox_app_secret"
    ],
    other_app: [peek_app_id: "other_app_id", peek_app_secret: "other_app_secret"]
  ]

# Configure Tesla adapter for tests
config :tesla, adapter: PeekAppSDK.MockTeslaClient
