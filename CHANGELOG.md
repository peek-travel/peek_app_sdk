# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2025-10-15]

### Changed
- **BREAKING**: Configuration key `peek_api_url` has been deprecated in favor of `peek_api_base_url`
  - The new `peek_api_base_url` should contain only the base URL (e.g., `"https://apps.peekapis.com"`)
  - The SDK automatically appends appropriate paths (e.g., `/backoffice-gql`) for different API endpoints
  - **Migration path**:
    - Existing apps using `peek_api_url` will continue to work for backoffice calls with deprecation warnings
    - New features like `update_configuration_status` will fail with clear migration instructions if `peek_api_url` is configured
    - Update your configuration from:
      ```elixir
      config :peek_app_sdk,
        peek_api_url: "https://apps.peekapis.com/backoffice-gql"
      ```
      to:
      ```elixir
      config :peek_app_sdk,
        peek_api_base_url: "https://apps.peekapis.com"
      ```

### Added
- Configuration validation that prevents use of deprecated `peek_api_url` with new features
- Deprecation warnings when using legacy `peek_api_url` configuration for backoffice calls
- Clear error messages with migration instructions for deprecated configuration

### Fixed
- URL construction now properly handles base URLs without hardcoded paths
