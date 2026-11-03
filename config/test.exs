import Config

# Configure peek_app_sdk for tests
config :peek_app_sdk,
  peek_app_secret: "test_secret",
  peek_app_id: "test_app_id",
  peek_api_base_url: "https://apps.example.peekapis.com",
  peek_api_key: "test_api_key",
  client_secret_token: "test_client_secret",
  # Centralized configuration structure
  apps: [
    project_name: [
      peek_app_id: "project_name_app_id",
      peek_api_key: "project_name_api_key",
      peek_app_secret: "project_name_app_secret",
      client_secret_token: "project_name_client_secret"
    ],
    other_app: [peek_app_id: "other_app_id", peek_app_secret: "other_app_secret"],
    client_only_app: [
      peek_app_id: "client_only_app_id",
      peek_app_secret: "client_only_app_secret",
      client_secret_token: "client_only_secret"
    ],
    # Incomplete app configs: get_config/1 must raise for these
    no_app_id_app: [peek_app_secret: "no_app_id_app_secret"],
    no_app_secret_app: [peek_app_id: "no_app_secret_app_id"],
    nil_app_secret_app: [peek_app_id: "nil_app_secret_app_id", peek_app_secret: nil],
    empty_app_id_app: [peek_app_id: "", peek_app_secret: "empty_app_id_app_secret"],
    blank_app_secret_app: [peek_app_id: "blank_app_secret_app_id", peek_app_secret: "  "],
    integer_app_secret_app: [peek_app_id: "integer_app_secret_app_id", peek_app_secret: 1234],
    nil_entry_app: nil
  ]

# Configure Tesla adapter for tests
config :tesla, adapter: Tesla.Adapter.Finch
