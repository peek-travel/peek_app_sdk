defmodule PeekAppSDK.AccountUserTest do
  use ExUnit.Case, async: true

  alias PeekAppSDK.AccountUser

  describe "hook/0" do
    test "returns a hook account user" do
      hook = AccountUser.hook()
      
      assert %AccountUser{} = hook
      assert hook.name == "hook"
      assert hook.email == nil
      assert hook.id == nil
      assert hook.is_peek_admin == nil
      assert hook.primary_role == nil
    end
  end
end
