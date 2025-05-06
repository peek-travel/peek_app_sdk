defmodule PeekAppSDK.Metrics do
  @moduledoc """
  This module provides functions for tracking metrics to Ahem.
  """

  defdelegate track_install(external_refid, name, is_test), to: PeekAppSDK.Metrics.Client
  defdelegate track_uninstall(external_refid, name, is_test), to: PeekAppSDK.Metrics.Client

  defdelegate track_event(
                external_refid,
                name,
                is_test,
                event_id,
                level \\ "info",
                anonymous_id \\ nil
              ),
              to: PeekAppSDK.Metrics.Client
end
