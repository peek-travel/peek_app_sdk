defmodule PeekAppSDK.TestHelpers do
  @moduledoc false

  def start_semnox do
    Application.ensure_all_started(:semnox)
  end
end
