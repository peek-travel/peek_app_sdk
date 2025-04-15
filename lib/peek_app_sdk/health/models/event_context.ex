defmodule PeekAppSDK.Health.Models.EventContext do
  @moduledoc """
  Represents the context information for an event in the Health API.

  ## Fields

  * `:channel` - Optional channel information (e.g., "web")
  * `:user_agent` - Optional user agent information
  * `:session_id` - Optional session ID
  * `:timezone` - Optional timezone information (e.g., "America/New_York")
  * `:ip` - Optional IP address
  * `:page` - Optional page information (e.g., "/dashboard")
  * `:screen` - Optional screen information (map with :height and :width)
  """

  @type t :: %__MODULE__{
          channel: String.t() | nil,
          user_agent: String.t() | nil,
          session_id: String.t() | nil,
          timezone: String.t() | nil,
          ip: String.t() | nil,
          page: String.t() | nil,
          screen: %{height: integer() | nil, width: integer() | nil} | nil
        }

  defstruct [
    :channel,
    :user_agent,
    :session_id,
    :timezone,
    :ip,
    :page,
    :screen
  ]

  @doc """
  Converts the EventContext struct to a map suitable for API requests.
  Converts keys to camelCase format and renames screen dimensions to match API expectations.

  ## Examples

      iex> context = %PeekAppSDK.Health.Models.EventContext{
      ...>   channel: "web",
      ...>   user_agent: "Mozilla/5.0",
      ...>   screen: %{height: 1080, width: 1920}
      ...> }
      iex> PeekAppSDK.Health.Models.EventContext.to_api_map(context)
      %{
        "channel" => "web",
        "userAgent" => "Mozilla/5.0",
        "screen" => %{
          "Height" => 1080,
          "Width" => 1920
        }
      }
  """
  @spec to_api_map(t()) :: map()
  def to_api_map(%__MODULE__{} = context) do
    context
    |> Map.from_struct()
    |> Enum.filter(fn {_k, v} -> v != nil end)
    |> Enum.map(fn
      {:user_agent, v} -> {"userAgent", v}
      {:session_id, v} -> {"sessionId", v}
      {:screen, %{height: height, width: width}} ->
        {"screen", %{"Height" => height, "Width" => width}}
      {k, v} -> {Atom.to_string(k), v}
    end)
    |> Map.new()
  end

  @doc """
  Creates an EventContext struct from a map.

  ## Examples

      iex> PeekAppSDK.Health.Models.EventContext.from_map(%{
      ...>   "channel" => "web",
      ...>   "userAgent" => "Mozilla/5.0",
      ...>   "screen" => %{"Height" => 1080, "Width" => 1920}
      ...> })
      %PeekAppSDK.Health.Models.EventContext{
        channel: "web",
        user_agent: "Mozilla/5.0",
        screen: %{height: 1080, width: 1920}
      }
  """
  @spec from_map(map()) :: t()
  def from_map(map) when is_map(map) do
    screen = case Map.get(map, "screen") do
      %{"Height" => height, "Width" => width} -> %{height: height, width: width}
      _ -> nil
    end

    %__MODULE__{
      channel: Map.get(map, "channel"),
      user_agent: Map.get(map, "userAgent"),
      session_id: Map.get(map, "sessionId"),
      timezone: Map.get(map, "timezone"),
      ip: Map.get(map, "ip"),
      page: Map.get(map, "page"),
      screen: screen
    }
  end
end
