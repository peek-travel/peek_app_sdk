defmodule PeekAppSDK.Health do
  @moduledoc """
  PeekAppSDK.Health provides functionality for tracking events, health checks, and usage metrics
  for monitored applications.

  This module follows the same configuration pattern as the main PeekAppSDK, allowing different
  applications to use their own credentials and settings.

  ## Basic Usage

  ```elixir
  # Create an event payload
  payload = %PeekAppSDK.Health.Models.EventPayload{
    event_id: "app.install",
    level: :info,
    anonymous_id: "anon-123456",
    context: %PeekAppSDK.Health.Models.EventContext{
      channel: "web",
      user_agent: "Mozilla/5.0"
    }
  }

  # Track an event using the default configuration
  PeekAppSDK.Health.track_event("monitored-app-id", payload)

  # Track an event using a specific application's configuration
  PeekAppSDK.Health.track_event("monitored-app-id", payload, :project_name)
  ```

  ## Configuration

  Configure your application with the required PeekAppSDK.Health settings:

  ```elixir
  # In config/config.exs or similar
  config :peek_app_sdk,
    # Existing PeekAppSDK configuration...
    health_api_url: "https://peek-labs-app-health-metrics.web.app",
    health_api_key: "HEALTH_API_KEY"
  ```

  You can also configure health-specific settings for individual applications:

  ```elixir
  config :peek_app_sdk,
    # Existing PeekAppSDK configuration...
    apps: [
      project_name: [
        # Existing app-specific configuration...
        health_api_key: "PROJECT_SPECIFIC_HEALTH_API_KEY"
      ]
    ]
  ```
  """

  alias PeekAppSDK.Health.Models.EventPayload
  alias PeekAppSDK.Health.Models.EventContext

  @doc """
  Tracks an event for a monitored application.

  ## Parameters

  * `monitored_app_id` - ID of the monitored application
  * `payload` - EventPayload struct containing event data
  * `config_id` - Optional configuration identifier

  ## Returns

  * `{:ok, response}` - If the event was successfully tracked
  * `{:error, reason}` - If there was an error tracking the event

  ## Examples

      iex> payload = %PeekAppSDK.Health.Models.EventPayload{
      ...>   event_id: "app.install",
      ...>   level: :info,
      ...>   anonymous_id: "anon-123456"
      ...> }
      iex> PeekAppSDK.Health.track_event("app-123", payload)
      {:ok, %{success: true, message: "Event tracked successfully", event_id: "1625097600000_abc123"}}
  """
  @spec track_event(String.t(), EventPayload.t(), atom() | nil) ::
          {:ok, map()} | {:error, any()}
  defdelegate track_event(monitored_app_id, payload, config_id \\ nil),
    to: PeekAppSDK.Health.Client

  @doc """
  Creates a new EventPayload struct with the given attributes.

  ## Parameters

  * `attrs` - Map of attributes for the EventPayload

  ## Returns

  * `%EventPayload{}` - A new EventPayload struct

  ## Examples

      iex> PeekAppSDK.Health.new_event_payload(%{
      ...>   event_id: "app.install",
      ...>   level: :info,
      ...>   anonymous_id: "anon-123456"
      ...> })
      %PeekAppSDK.Health.Models.EventPayload{
        event_id: "app.install",
        level: :info,
        anonymous_id: "anon-123456"
      }
  """
  @spec new_event_payload(map()) :: EventPayload.t()
  def new_event_payload(attrs) when is_map(attrs) do
    context =
      case Map.get(attrs, :context) do
        context_attrs when is_map(context_attrs) -> struct(EventContext, context_attrs)
        %EventContext{} = context -> context
        _ -> nil
      end

    attrs = if context, do: Map.put(attrs, :context, context), else: attrs
    struct(EventPayload, attrs)
  end

  @doc """
  Creates a new EventContext struct with the given attributes.

  ## Parameters

  * `attrs` - Map of attributes for the EventContext

  ## Returns

  * `%EventContext{}` - A new EventContext struct

  ## Examples

      iex> PeekAppSDK.Health.new_event_context(%{
      ...>   channel: "web",
      ...>   user_agent: "Mozilla/5.0"
      ...> })
      %PeekAppSDK.Health.Models.EventContext{
        channel: "web",
        user_agent: "Mozilla/5.0"
      }
  """
  @spec new_event_context(map()) :: EventContext.t()
  def new_event_context(attrs) when is_map(attrs) do
    struct(EventContext, attrs)
  end

  @doc """
  Tracks an info-level event for a monitored application.

  This is a convenience function that creates an EventPayload with level: :info.

  ## Parameters

  * `monitored_app_id` - ID of the monitored application
  * `event_id` - Identifier for the type of event
  * `anonymous_id` - Anonymous identifier for the user or session
  * `opts` - Optional parameters for the event payload
  * `config_id` - Optional configuration identifier

  ## Returns

  * `{:ok, response}` - If the event was successfully tracked
  * `{:error, reason}` - If there was an error tracking the event

  ## Examples

      iex> PeekAppSDK.Health.track_info_event("app-123", "app.install", "anon-123456")
      {:ok, %{success: true, message: "Event tracked successfully", event_id: "1625097600000_abc123"}}

      iex> PeekAppSDK.Health.track_info_event("app-123", "app.install", "anon-123456", %{
      ...>   user_id: "user-789012",
      ...>   context: %{channel: "web"}
      ...> })
      {:ok, %{success: true, message: "Event tracked successfully", event_id: "1625097600000_abc123"}}
  """
  @spec track_info_event(String.t(), String.t(), String.t(), map(), atom() | nil) ::
          {:ok, map()} | {:error, any()}
  def track_info_event(monitored_app_id, event_id, anonymous_id, opts \\ %{}, config_id \\ nil) do
    # Extract context from opts
    {context, opts} =
      case Map.pop(opts, :context) do
        {%EventContext{} = ctx, new_opts} ->
          {ctx, new_opts}

        {context_attrs, new_opts} when is_map(context_attrs) ->
          {new_event_context(context_attrs), new_opts}

        {nil, new_opts} ->
          {nil, new_opts}
      end

    # Create a new map with all the required fields
    payload_attrs =
      Map.merge(opts, %{
        event_id: event_id,
        level: :info,
        anonymous_id: anonymous_id
      })

    # Add context if it exists
    payload_attrs = if context, do: Map.put(payload_attrs, :context, context), else: payload_attrs

    # Create the payload struct
    payload = new_event_payload(payload_attrs)

    track_event(monitored_app_id, payload, config_id)
  end

  @doc """
  Tracks an error-level event for a monitored application.

  This is a convenience function that creates an EventPayload with level: :error.

  ## Parameters

  * `monitored_app_id` - ID of the monitored application
  * `event_id` - Identifier for the type of event
  * `anonymous_id` - Anonymous identifier for the user or session
  * `opts` - Optional parameters for the event payload
  * `config_id` - Optional configuration identifier

  ## Returns

  * `{:ok, response}` - If the event was successfully tracked
  * `{:error, reason}` - If there was an error tracking the event

  ## Examples

      iex> PeekAppSDK.Health.track_error_event("app-123", "app.error", "anon-123456")
      {:ok, %{success: true, message: "Event tracked successfully", event_id: "1625097600000_abc123"}}

      iex> PeekAppSDK.Health.track_error_event("app-123", "app.error", "anon-123456", %{
      ...>   user_id: "user-789012",
      ...>   context: %{channel: "web"}
      ...> })
      {:ok, %{success: true, message: "Event tracked successfully", event_id: "1625097600000_abc123"}}
  """
  @spec track_error_event(String.t(), String.t(), String.t(), map(), atom() | nil) ::
          {:ok, map()} | {:error, any()}
  def track_error_event(monitored_app_id, event_id, anonymous_id, opts \\ %{}, config_id \\ nil) do
    # Extract context from opts
    {context, opts} =
      case Map.pop(opts, :context) do
        {%EventContext{} = ctx, new_opts} ->
          {ctx, new_opts}

        {context_attrs, new_opts} when is_map(context_attrs) ->
          {new_event_context(context_attrs), new_opts}

        {nil, new_opts} ->
          {nil, new_opts}
      end

    # Create a new map with all the required fields
    payload_attrs =
      Map.merge(opts, %{
        event_id: event_id,
        level: :error,
        anonymous_id: anonymous_id
      })

    # Add context if it exists
    payload_attrs = if context, do: Map.put(payload_attrs, :context, context), else: payload_attrs

    # Create the payload struct
    payload = new_event_payload(payload_attrs)

    track_event(monitored_app_id, payload, config_id)
  end
end
