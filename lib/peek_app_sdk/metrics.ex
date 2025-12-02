defmodule PeekAppSDK.Metrics do
  @moduledoc """
  This module provides functions for tracking metrics to Ahem.
  """

  defdelegate identify(partner),
    to: PeekAppSDK.Metrics.PostHog

  defdelegate track_install(external_refid, name, is_test, opts \\ []),
    to: PeekAppSDK.Metrics.Client

  def track_install(%{external_refid: external_refid, name: name, is_test: is_test} = partner, opts \\ []) do
    track_install(external_refid, name, is_test, opts)
    identify(partner)
    track(partner, "app.install", %{})
  end

  defdelegate track_uninstall(external_refid, name, is_test, opts \\ []),
    to: PeekAppSDK.Metrics.Client

  def track_uninstall(%{external_refid: external_refid, name: name, is_test: is_test} = partner, opts \\ []) do
    track_uninstall(external_refid, name, is_test, opts)
    track(partner, "app.uninstall", %{})
  end

  defdelegate update_configuration_status(install_id, status, notes \\ nil),
    to: PeekAppSDK.Metrics.Client

  @doc """
  Tracks an event with the given event ID and payload.

  This function takes an event ID and a map of options and sends them directly to the API
  without any validation or transformation. The only required field in the options map is
  `eventId`, which is automatically added based on the first parameter.

  ## Parameters

    * `event_id` - The ID of the event to track
    * `payload` - A map of fields to include in the event payload

  ## Examples

      iex> PeekAppSDK.Metrics.track("app.install", %{
      ...>   anonymousId: "partner-123",
      ...>   level: "info",
      ...>   usageDisplay: "New App Installs",
      ...>   usageDetails: "Partner Name",
      ...>   postMessage: "Partner Name installed"
      ...> })
      {:ok, %{...}}

  ## Example with all possible fields

      iex> PeekAppSDK.Metrics.track("app.install", %{
      ...>   // Required
      ...>   anonymousId: "partner-123",
      ...>   level: "info",
      ...>   // Optional, useful for additional metrics features
      ...>   usageDisplay: "New App Installs",
      ...>   usageDetails: "Bob's Surf",
      ...>   postMessage: "Bob's Surf installed",
      ...>   // Optional, useful for data analysis
      ...>   userId: "user-123",
      ...>   idempotencyKey: "unique-key-789",
      ...>   context: %{
      ...>     channel: "web",
      ...>     userAgent: "Mozilla/5.0",
      ...>     sessionId: "session-123",
      ...>     timezone: "America/Los_Angeles",
      ...>     ip: "192.168.1.1",
      ...>     page: "/install",
      ...>     screen: %{
      ...>       height: 1080,
      ...>       width: 1920
      ...>     }
      ...>   },
      ...>   customFields: %{
      ...>     "partnerId": "partner-123",
      ...>     "partnerName": "Bob's Surf",
      ...>     "partnerIsTest": false
      ...>   }
      ...> })
      {:ok, %{...}}
  """
  defdelegate track(event_id, payload), to: PeekAppSDK.Metrics.Client

  defdelegate track(partner, event, params), to: PeekAppSDK.Metrics.PostHog
end
