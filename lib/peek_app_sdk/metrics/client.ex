defmodule PeekAppSDK.Metrics.Client do
  use Tesla

  @moduledoc """
  Client for sending metrics to the Peek Pro metrics service.
  """

  plug Tesla.Middleware.JSON
  plug Tesla.Middleware.Headers, [{"Content-Type", "application/json"}]
  plug Tesla.Middleware.Retry, delay: 500, max_retries: 10

  defp event_url,
    do: "https://ahem.peeklabs.com/events/#{Application.fetch_env!(:peek_app_sdk, :peek_app_id)}"

  defp do_post!(body, _opts \\ []) do
    response = post!(event_url(), body)

    case response do
      %Tesla.Env{status: 202} ->
        :ok

      %Tesla.Env{status: status, body: _body} ->
        {:error, status}
    end

    {:ok, body}
  end

  @doc """
  Tracks an app installation event.

  ## Parameters

    * `external_refid` - The external reference ID for the partner
    * `name` - The name of the partner
    * `is_test` - Boolean indicating if this is a test installation

  ## Examples

      iex> PeekAppSDK.Metrics.Client.track_install("partner-123", "Partner Name", false)
      {:ok, %{...}}

  """
  def track_install(external_refid, name, is_test) do
    usage_display = if is_test, do: "New TEST App Installs", else: "New App Installs"

    do_post!(%{
      eventId: "app.install",
      level: "info",
      anonymousId: external_refid,
      usageDisplay: usage_display,
      usageDetails: name,
      postMessage: "#{name} installed",
      customFields: base_custom_fields(name, external_refid, is_test)
    })
  end

  @doc """
  Tracks an app uninstallation event.

  ## Parameters

    * `external_refid` - The external reference ID for the partner
    * `name` - The name of the partner
    * `is_test` - Boolean indicating if this is a test installation

  ## Examples

      iex> PeekAppSDK.Metrics.Client.track_uninstall("partner-123", "Partner Name", false)
      {:ok, %{...}}

  """
  def track_uninstall(external_refid, name, is_test) do
    usage_display = if is_test, do: "New TEST App Uninstalls", else: "New App Uninstalls"

    do_post!(%{
      eventId: "app.uninstall",
      level: "info",
      anonymousId: external_refid,
      usageDisplay: usage_display,
      usageDetails: name,
      postMessage: "#{name} uninstalled",
      customFields: base_custom_fields(name, external_refid, is_test)
    })
  end

  @doc """
  Tracks a custom event.

  ## Parameters

    * `external_refid` - The external reference ID for the partner
    * `name` - The name of the partner
    * `is_test` - Boolean indicating if this is a test installation
    * `event_id` - The ID of the event to track
    * `level` - The level of the event (default: "info")
    * `anonymous_id` - Optional anonymous ID to use instead of external_refid

  ## Examples

      iex> PeekAppSDK.Metrics.Client.track_event("partner-123", "Partner Name", false, "custom.event")
      {:ok, %{...}}

  """
  def track_event(
        external_refid,
        name,
        is_test,
        event_id,
        level \\ "info",
        anonymous_id \\ nil
      ) do
    do_post!(%{
      eventId: event_id,
      level: level,
      anonymousId: anonymous_id || external_refid,
      customFields: base_custom_fields(name, external_refid, is_test)
    })
  end

  defp base_custom_fields(name, external_refid, is_test) do
    %{
      "partnerName" => name,
      "partnerExternalRefid" => external_refid,
      "partnerIsTest" => is_test
    }
  end
end
