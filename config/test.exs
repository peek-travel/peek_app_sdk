import Config

config :semnox,
  peek_app_secret: "semnox_test_secret",
  peek_app_id: "semnox_test_app_id"

# Configure peek_app_sdk for tests
config :peek_app_sdk,
  peek_app_secret: "test_secret",
  peek_app_id: "test_app_id",
  peek_api_url: "https://noreaga.peek.com/apps/backoffice-gql",
  peek_app_key: "test_app_key"

# Configure Tesla adapter for tests
config :tesla, adapter: PeekAppSDK.MockTeslaClient
