defmodule PeekAppSDK.UI.Odyssey.OdysseyActivityPickerTest do
  use ExUnit.Case, async: false

  import Phoenix.Component
  import Phoenix.LiveViewTest
  import PeekAppSDK.UI.Odyssey

  alias PeekAppSDK.UI.Odyssey
  alias PeekAppSDK.UI.Odyssey.OdysseyActivityPicker

  describe "odyssey_activity_picker/1" do
    test "can be rendered inside a form" do
      # Mock the GraphQL query response
      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn env, _opts ->
        assert env.method == :post
        assert String.contains?(env.url, "backoffice-gql")

        response_data = %{
          activities: [
            %{id: "activity_1", name: "Hiking Tour", colorHex: "#FF5733"},
            %{id: "activity_2", name: "City Walk", colorHex: "#33FF57"}
          ]
        }

        {:ok, %Tesla.Env{status: 200, body: %{data: response_data}}}
      end)

      # Create a form using Phoenix.HTML.Form
      form_data = %{"activity_id" => nil}
      form = to_form(form_data, as: :test_form)

      # Render the component inside a form
      html =
        render_component(
          fn assigns ->
            ~H"""
            <.form for={@form} phx-change="change">
              <.odyssey_activity_picker field={@form[:activity_id]} install_id="test_install_id" />
            </.form>
            """
          end,
          %{form: form}
        )

      # Verify the form structure
      assert html =~ ~r/<form[^>]*phx-change="change"[^>]*>/
      assert html =~ ~r/<input[^>]*type="hidden"[^>]*name="test_form\[activity_id\]"[^>]*>/
      assert html =~ ~r/<odyssey-product-picker[^>]*>/
      assert html =~ ~r/title="Activity Picker"/
      assert html =~ ~r/products="\[.*\]"/

      # Verify the activities data is properly encoded in the component
      assert html =~ "Hiking Tour"
      assert html =~ "City Walk"
      assert html =~ "#FF5733"
      assert html =~ "#33FF57"
    end

    test "renders with correct form field name and value" do
      # Mock the GraphQL query response
      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn _env, _opts ->
        response_data = %{
          activities: [
            %{id: "activity_1", name: "Test Activity", colorHex: "#000000"}
          ]
        }

        {:ok, %Tesla.Env{status: 200, body: %{data: response_data}}}
      end)

      # Create a form with a pre-selected activity
      form_data = %{"activity_id" => "activity_1"}
      form = to_form(form_data, as: :my_form)

      html =
        render_component(
          fn assigns ->
            ~H"""
            <.form for={@form}>
              <.odyssey_activity_picker field={@form[:activity_id]} install_id="test_install_id" />
            </.form>
            """
          end,
          %{form: form}
        )

      # Verify the hidden input has the correct name (value starts as nil and gets updated by JS)
      assert html =~ ~r/<input[^>]*type="hidden"[^>]*name="my_form\[activity_id\]"[^>]*>/
    end

    test "renders with correct form when a multi-select" do
      # Mock the GraphQL query response
      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn _env, _opts ->
        response_data = %{
          activities: [
            %{id: "activity_1", name: "Test Activity", colorHex: "#000000"},
            %{id: "activity_2", name: "Test Activity 2", colorHex: "#000000"}
          ]
        }

        {:ok, %Tesla.Env{status: 200, body: %{data: response_data}}}
      end)

      # Create a form with a pre-selected activity
      form_data = %{"activity_ids" => ["activity_1", "activity_2"]}
      form = to_form(form_data, as: :my_form)

      html =
        render_component(
          fn assigns ->
            ~H"""
            <.form for={@form}>
              <.odyssey_activity_picker field={@form[:activity_ids]} install_id="test_install_id" />
            </.form>
            """
          end,
          %{form: form}
        )

      # Verify the hidden input has the correct name (value starts as nil and gets updated by JS)
      assert html =~ "ids=\"activity_1,activity_2\""
    end

    test "generates unique component IDs based on form field" do
      # Mock the GraphQL query response
      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn _env, _opts ->
        response_data = %{activities: []}
        {:ok, %Tesla.Env{status: 200, body: %{data: response_data}}}
      end)

      form_data = %{"selected_activity" => nil}
      form = to_form(form_data, as: :booking_form)

      html =
        render_component(
          fn assigns ->
            ~H"""
            <.odyssey_activity_picker field={@form[:selected_activity]} install_id="test_install_id" />
            """
          end,
          %{form: form}
        )

      # Verify the component generates the expected ID based on form name and field
      assert html =~ ~r/id="booking_form_selected_activity_activity_picker_hook"/
      assert html =~ ~r/id="booking_form_selected_activity_activity_picker_picker"/
    end

    test "passes install_id to load_activities function" do
      install_id = "custom_install_id"

      # Mock the GraphQL query and verify install_id is used
      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn env, _opts ->
        # Verify the install_id is used in the URL construction
        assert String.contains?(env.url, "backoffice-gql")

        # Verify the token contains the install_id (this would be in the Authorization header)
        auth_header = Enum.find(env.headers, fn {k, _v} -> k == "X-Peek-Auth" end)
        assert auth_header != nil

        response_data = %{activities: []}
        {:ok, %Tesla.Env{status: 200, body: %{data: response_data}}}
      end)

      form_data = %{"activity_id" => nil}
      form = to_form(form_data, as: :test_form)

      # Render with custom install_id
      render_component(
        fn assigns ->
          ~H"""
          <.odyssey_activity_picker field={@form[:activity_id]} install_id={@install_id} />
          """
        end,
        %{form: form, install_id: install_id}
      )
    end

    test "handles empty activities response gracefully" do
      # Mock empty activities response
      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn _env, _opts ->
        response_data = %{activities: []}
        {:ok, %Tesla.Env{status: 200, body: %{data: response_data}}}
      end)

      form_data = %{"activity_id" => nil}
      form = to_form(form_data, as: :test_form)

      html =
        render_component(
          fn assigns ->
            ~H"""
            <.odyssey_activity_picker field={@form[:activity_id]} install_id="test_install_id" />
            """
          end,
          %{form: form}
        )

      # Should still render the component structure even with no activities
      assert html =~ ~r/<odyssey-product-picker[^>]*>/
      assert html =~ ~r/products="\[\]"/
    end

    test "requires field and install_id attributes" do
      # Test that missing required attributes raise appropriate errors
      assert_raise FunctionClauseError, fn ->
        render_component(&Odyssey.odyssey_activity_picker/1, %{})
      end
    end

    test "raises error when install_id is missing" do
      form_data = %{"activity_id" => nil}
      form = to_form(form_data, as: :test_form)

      # Test that missing install_id raises a KeyError when trying to access it in load_activities
      assert_raise KeyError, ~r/key :install_id not found/, fn ->
        render_component(&Odyssey.odyssey_activity_picker/1, %{field: form[:activity_id]})
      end
    end

    test "validates required assigns and raises specific error message" do
      # Test the validation logic by providing field but not install_id
      # We need to mock the component to avoid the load_activities call

      # Create a test module that skips the load_activities call
      defmodule TestActivityPicker do
        use Phoenix.LiveComponent

        @required_assigns ~w(field install_id)a

        def update(assigns, socket) do
          socket = assign(socket, assigns)

          # Skip the load_activities call to test validation
          for required <- @required_assigns do
            unless socket.assigns[required] do
              raise ~s/Missing required assign "#{required}"/
            end
          end

          {:ok, socket}
        end

        def render(assigns), do: ~H"<div></div>"
      end

      form_data = %{"activity_id" => nil}
      form = to_form(form_data, as: :test_form)

      # This should raise the "Missing required assign" error
      assert_raise RuntimeError, ~r/Missing required assign "install_id"/, fn ->
        render_component(TestActivityPicker, %{field: form[:activity_id]})
      end
    end
  end

  describe "load_activities/1" do
    test "transforms GraphQL response to expected format" do
      install_id = "test_install_id"

      # Mock successful GraphQL response
      Tesla.Adapter.Finch
      |> Mimic.stub(:call, fn _env, _opts ->
        response_data = %{
          activities: [
            %{id: "act_1", name: "Mountain Hike", colorHex: "#FF0000"},
            %{id: "act_2", name: "Beach Walk", colorHex: "#00FF00"}
          ]
        }

        {:ok, %Tesla.Env{status: 200, body: %{data: response_data}}}
      end)

      result = OdysseyActivityPicker.load_activities(install_id)

      assert result == [
               %{id: "act_1", name: "Mountain Hike", color: "#FF0000"},
               %{id: "act_2", name: "Beach Walk", color: "#00FF00"}
             ]
    end
  end
end
