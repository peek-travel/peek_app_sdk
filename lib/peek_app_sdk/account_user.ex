defmodule PeekAppSDK.AccountUser do
  @moduledoc """
  When iFrames are loaded, who is the logged in user?
  """
  @enforce_keys [:email, :id, :is_peek_admin, :name, :primary_role]
  defstruct [:email, :id, :is_peek_admin, :name, :primary_role, locale: nil]

  @type t :: %__MODULE__{
          email: String.t(),
          id: String.t(),
          is_peek_admin: boolean(),
          name: String.t(),
          primary_role: String.t() | nil,
          locale: String.t() | nil
        }

  @doc """
  When events are broadcast there isn't a user associated, this is how
  PeekPro identifies them.
  """
  def hook do
    %__MODULE__{
      name: "hook",
      email: nil,
      id: nil,
      is_peek_admin: nil,
      primary_role: nil
    }
  end
end
