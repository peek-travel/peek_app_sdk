# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2025-12-02]

### Added
- Events can now be routed to a PostHog project of your choosing by configuring `:posthog_key`.
  - `PeekAppSDK.Metrics.track_install/2` will automatically identify the partner in PostHog on install (sets `name` and `is_test`) and then capture `app.install`.
  - `PeekAppSDK.Metrics.track/3` (partner variant) sends custom events to PostHog and automatically includes `distinct_id`, `partner_id`, `partner_name`, `partner_is_test`, and `app_slug`.

### Changed
- BREAKING: Metrics API is now partner-first for key functions:
  - `PeekAppSDK.Metrics.track/3` now expects a partner map as the first argument when routing to PostHog (`track(partner, event_id, payload)`).
  - `PeekAppSDK.Metrics.track_install/2` now expects a partner map as the first argument and will identify + capture in PostHog when configured.
  - `PeekAppSDK.Metrics.track_uninstall/2` now expects a partner map as the first argument and will capture `app.uninstall` in PostHog when configured.

Migration examples:
- Before:
  - `PeekAppSDK.Metrics.track("order.placed", %{anonymousId: partner_id, level: "info"})`
  - `PeekAppSDK.Metrics.track_install(partner_id, partner_name, is_test)`
  - `PeekAppSDK.Metrics.track_uninstall(partner_id, partner_name, is_test)`
- After:
  - `PeekAppSDK.Metrics.track(%{external_refid: partner_id, name: partner_name, is_test: is_test}, "order.placed", %{level: "info"})`
  - `PeekAppSDK.Metrics.track_install(%{external_refid: partner_id, name: partner_name, is_test: is_test})`
  - `PeekAppSDK.Metrics.track_uninstall(%{external_refid: partner_id, name: partner_name, is_test: is_test})`

Note: Legacy arities remain temporarily for compatibility but are considered deprecated and may be removed in the next major release.

### Fixed
- Cosmetic fix for the activity picker component.

## [2025-11-25]

### Changed

- Updated core Odyssey `a.btn` button link styling in `assets/components/core-components.css` to remove underlines from button links per internal design rules.

## [2025-11-24]

### Added

- Added new icon variants to `odyssey_icon`: `alert`, `warning`, `info`, `success`, `cancel`, `arrow-left`, `trashcan`, and `loading`.

## [2025-11-20]

### Added

- Added `odyssey_prefix_input` component for prefixed inputs (for example currency and percentages) in the Odyssey UI library.
  - Supports both standalone usage and `Phoenix.HTML.Form` field integration.
  - Documented and showcased in the demo app under the Forms tab with discount and percentage examples.
- Added `odyssey_date_picker` component for selecting dates with Odyssey styling and icons.
  - Supports both standalone usage and `Phoenix.HTML.Form` field integration.
  - Included in the demo app under the Forms tab with start/expiration date examples.
  - Ships with focused tests to keep Odyssey UI coverage high.

### Changed

- Updated Odyssey `.btn` disabled styles so each variant keeps its own color when disabled, instead of using DaisyUI's generic disabled background.

### Fixed

- Fixed a bug where changeset errors were being reset and not displayed by the prefix input when used with a form field; validation errors from the changeset now render correctly.

## [2025-11-11]

### Added

- Added optional `label` attribute to `odyssey_activity_picker` component
  - When a label is provided, the activity picker is automatically wrapped in a fieldset with proper label styling
  - Follows the same pattern as Phoenix core input components for consistency
  - Maintains 100% backward compatibility - existing usage without labels continues to work unchanged

### Fixed

- Toggle button no longer emits an event when clicking the already-selected option, preventing redundant LiveView events in both standalone and form-integrated usage.

## [2025-11-07]

### Added

- Added optional `label` attribute to `odyssey_toggle_button` and `odyssey_toggle_button_input` components
  - When a label is provided, the toggle button is automatically wrapped in a fieldset with proper label styling
  - Follows the same pattern as Phoenix core input components for consistency
  - Maintains 100% backward compatibility - existing usage without labels continues to work unchanged
  - Works seamlessly with both standalone and form-integrated usage

## [2025-11-04]

### Added

- Added `odyssey_toggle_button` component from Odyssey
- Created the beginning of a demo project

### Removed

- **BREAKING**: Removed core components - applications should use their own core component file from Phoenix instead of relying on shared components to make Phoenix upgrades easier

## [2025-10-15]

### Changed

- **BREAKING**: Configuration key `peek_app_key` has been renamed to `peek_api_key`
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

- Support for passing `x-peek-auth` token in request body parameters for scenarios where custom headers cannot be controlled (e.g., form submissions, third-party integrations)
  - Body parameters take precedence over headers when both are present
  - Enables authentication in form submission scenarios and legacy systems
- Configuration validation that prevents use of deprecated `peek_api_url` with new features
- Deprecation warnings when using legacy `peek_api_url` configuration for backoffice calls
- Clear error messages with migration instructions for deprecated configuration

### Fixed

- URL construction now properly handles base URLs without hardcoded paths
