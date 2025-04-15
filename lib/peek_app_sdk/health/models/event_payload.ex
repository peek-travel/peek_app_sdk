defmodule PeekAppSDK.Health.Models.EventPayload do
  @moduledoc """
  Represents the payload for tracking an event in the Health API.

  ## Fields

  * `:event_id` - Identifier for the type of event (required)
  * `:level` - Level of the event (required, "info" or "error")
  * `:anonymous_id` - Anonymous identifier for the user or session (required)
  * `:user_id` - Optional identifier for the authenticated user
  * `:idempotency_key` - Optional key to prevent duplicate event processing
  * `:context` - Optional context information (EventContext struct)
  * `:usage_display` - Optional display name for usage reporting
  * `:usage_details` - Optional details for usage reporting
  * `:post_message` - Optional message to post to notification channels
  * `:custom_fields` - Optional custom fields for the event (map)
  """

  alias PeekAppSDK.Health.Models.EventContext

  @type level :: :info | :error

  @type t :: %__MODULE__{
          event_id: String.t(),
          level: level(),
          anonymous_id: String.t(),
          user_id: String.t() | nil,
          idempotency_key: String.t() | nil,
          context: EventContext.t() | nil,
          usage_display: String.t() | nil,
          usage_details: String.t() | nil,
          post_message: String.t() | nil,
          custom_fields: map() | nil
        }

  defstruct [
    :event_id,
    :level,
    :anonymous_id,
    :user_id,
    :idempotency_key,
    :context,
    :usage_display,
    :usage_details,
    :post_message,
    :custom_fields
  ]

  @doc """
  Validates an EventPayload struct.

  Returns `:ok` if the payload is valid, or `{:error, reason}` if it's invalid.

  ## Examples

      iex> payload = %PeekAppSDK.Health.Models.EventPayload{
      ...>   event_id: "app.install",
      ...>   level: :info,
      ...>   anonymous_id: "anon-123456"
      ...> }
      iex> PeekAppSDK.Health.Models.EventPayload.validate(payload)
      :ok

      iex> payload = %PeekAppSDK.Health.Models.EventPayload{
      ...>   event_id: "app.install",
      ...>   level: :invalid,
      ...>   anonymous_id: "anon-123456"
      ...> }
      iex> PeekAppSDK.Health.Models.EventPayload.validate(payload)
      {:error, "Invalid level: :invalid. Must be :info or :error"}

      iex> payload = %PeekAppSDK.Health.Models.EventPayload{
      ...>   level: :info,
      ...>   anonymous_id: "anon-123456"
      ...> }
      iex> PeekAppSDK.Health.Models.EventPayload.validate(payload)
      {:error, "Missing required field: event_id"}
  """
  @spec validate(t()) :: :ok | {:error, String.t()}
  def validate(%__MODULE__{} = payload) do
    cond do
      is_nil(payload.event_id) ->
        {:error, "Missing required field: event_id"}

      is_nil(payload.level) ->
        {:error, "Missing required field: level"}

      payload.level not in [:info, :error] ->
        {:error, "Invalid level: #{inspect(payload.level)}. Must be :info or :error"}

      is_nil(payload.anonymous_id) ->
        {:error, "Missing required field: anonymous_id"}

      true ->
        :ok
    end
  end

  @doc """
  Converts the EventPayload struct to a map suitable for API requests.
  Converts keys to camelCase format and converts the level atom to string.

  ## Examples

      iex> payload = %PeekAppSDK.Health.Models.EventPayload{
      ...>   event_id: "app.install",
      ...>   level: :info,
      ...>   anonymous_id: "anon-123456",
      ...>   context: %PeekAppSDK.Health.Models.EventContext{
      ...>     channel: "web"
      ...>   }
      ...> }
      iex> PeekAppSDK.Health.Models.EventPayload.to_api_map(payload)
      %{
        "eventId" => "app.install",
        "level" => "info",
        "anonymousId" => "anon-123456",
        "context" => %{
          "channel" => "web"
        }
      }
  """
  @spec to_api_map(t()) :: map()
  def to_api_map(%__MODULE__{} = payload) do
    context = if payload.context, do: EventContext.to_api_map(payload.context), else: nil

    payload
    |> Map.from_struct()
    |> Enum.filter(fn {_k, v} -> v != nil end)
    |> Enum.map(fn
      {:event_id, v} -> {"eventId", v}
      {:level, v} -> {"level", Atom.to_string(v)}
      {:anonymous_id, v} -> {"anonymousId", v}
      {:user_id, v} -> {"userId", v}
      {:idempotency_key, v} -> {"idempotencyKey", v}
      {:context, _v} -> {"context", context}
      {:usage_display, v} -> {"usageDisplay", v}
      {:usage_details, v} -> {"usageDetails", v}
      {:post_message, v} -> {"postMessage", v}
      {:custom_fields, v} -> {"customFields", v}
    end)
    |> Map.new()
  end

  @doc """
  Creates an EventPayload struct from a map.

  ## Examples

      iex> PeekAppSDK.Health.Models.EventPayload.from_map(%{
      ...>   "eventId" => "app.install",
      ...>   "level" => "info",
      ...>   "anonymousId" => "anon-123456",
      ...>   "context" => %{
      ...>     "channel" => "web"
      ...>   }
      ...> })
      %PeekAppSDK.Health.Models.EventPayload{
        event_id: "app.install",
        level: :info,
        anonymous_id: "anon-123456",
        context: %PeekAppSDK.Health.Models.EventContext{
          channel: "web"
        }
      }
  """
  @spec from_map(map()) :: t()
  def from_map(map) when is_map(map) do
    context = case Map.get(map, "context") do
      context when is_map(context) -> EventContext.from_map(context)
      _ -> nil
    end

    level = case Map.get(map, "level") do
      "info" -> :info
      "error" -> :error
      _ -> nil
    end

    %__MODULE__{
      event_id: Map.get(map, "eventId"),
      level: level,
      anonymous_id: Map.get(map, "anonymousId"),
      user_id: Map.get(map, "userId"),
      idempotency_key: Map.get(map, "idempotencyKey"),
      context: context,
      usage_display: Map.get(map, "usageDisplay"),
      usage_details: Map.get(map, "usageDetails"),
      post_message: Map.get(map, "postMessage"),
      custom_fields: Map.get(map, "customFields")
    }
  end
end
