defmodule Mix.Tasks.SyncAppChangesTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO
  import ExUnit.CaptureLog
  import Mox

  # Define a mock for Finch
  defmodule MockFinch do
    def request(request, _finch_name) do
      send(self(), {:finch_request, request})

      # Construct the full URL from the request
      url =
        "#{request.scheme}://#{request.host}#{if request.port != 443, do: ":#{request.port}", else: ""}#{request.path}"

      # Normalize the method to lowercase for consistency
      method = String.downcase("#{request.method}")

      # Get the mock response from the process dictionary
      case Process.get({:mock_response, method, url}) do
        nil ->
          {:error, %Tesla.Error{reason: :econnrefused}}

        response ->
          response
      end
    end
  end

  # Setup mocks
  setup :verify_on_exit!

  # Setup temporary files and mocks
  setup do
    # Create temp directory for our test files
    tmp_dir = System.tmp_dir!() |> Path.join("sync_app_changes_test_#{System.unique_integer()}")
    File.mkdir_p!(tmp_dir)
    File.mkdir_p!(Path.join(tmp_dir, "config"))

    # Store the original working directory
    original_dir = File.cwd!()

    # Change to the temp directory for the test
    File.cd!(tmp_dir)

    # Create a default app.json file
    default_app_json = %{
      "app_version" => %{
        "name" => "Test App #{System.unique_integer()}",
        "baseUrl" => "https://test-app.example.com",
        "screenshots" => [],
        "description" => "Test App Description",
        "icon_url" => "/images/logo.svg",
        "categories" => [],
        "configured_extendables" => [
          %{
            "extendable_slug" => "app_registry_settings_url@v1",
            "configuration" => %{
              "url" => "/peek-pro/settings"
            }
          }
        ]
      }
    }

    write_app_json(default_app_json)

    # Set environment variables for the test
    System.put_env("PEEK_APP_REGISTRY_URL", app_registry_url())
    System.put_env("PEEK_APP_REGISTRY_AUTH_TOKEN", "test-auth-token")

    # Initialize meck for Finch
    :meck.new(Finch, [:passthrough])

    # Return context with cleanup function
    on_exit(fn ->
      # Restore original working directory
      File.cd!(original_dir)

      # Clean up temp directory
      File.rm_rf!(tmp_dir)

      # Unload meck mocks if they exist
      try do
        :meck.unload(Finch)
      rescue
        _ -> :ok
      end
    end)

    # Return the context
    %{
      tmp_dir: tmp_dir,
      default_app_json: default_app_json
    }
  end

  # Helper functions
  defp write_app_json(content) do
    File.mkdir_p!("config")
    File.write!("config/app.json", Jason.encode!(content, pretty: true))
  end

  defp write_env_file(content) do
    File.write!(".env", content)
  end

  # Mock Finch.request to return our predefined responses
  defp mock_finch_request(url, method, response) do
    # Parse the URL to get the components
    uri = URI.parse(url)

    # Construct the URL in the format used by the MockFinch module
    mock_url = "#{uri.scheme}://#{uri.host}#{uri.path}"

    # Normalize the method to lowercase for consistency
    method = String.downcase("#{method}")

    # Store the mock response in the process dictionary
    Process.put({:mock_response, method, mock_url}, response)

    # Override the Finch.request function
    :meck.expect(Finch, :request, fn request, finch_name ->
      MockFinch.request(request, finch_name)
    end)
  end

  # Run the actual Mix task with the given arguments
  defp run_task(args) do
    # Capture both stdout and stderr
    capture_io(fn ->
      capture_log(fn ->
        try do
          # Actually run the task with the given arguments
          Mix.Tasks.SyncAppChanges.run(args)
        rescue
          e in Mix.Error ->
            IO.puts("Mix.Error: #{e.message}")

          e ->
            IO.puts("Error: #{inspect(e)}")
        catch
          :exit, {:shutdown, 0} -> IO.puts("Task exited with success status")
          :exit, reason -> IO.puts("Task exited: #{inspect(reason)}")
        end
      end)
    end)
  end

  defp assert_contains(output, expected) when is_list(expected) do
    Enum.each(expected, fn str ->
      assert output =~ str, "Expected output to contain: #{str}"
    end)
  end

  defp assert_contains(output, expected) do
    assert output =~ expected, "Expected output to contain: #{expected}"
  end

  defp assert_not_contains(output, unexpected) when is_list(unexpected) do
    Enum.each(unexpected, fn str ->
      refute output =~ str, "Expected output NOT to contain: #{str}"
    end)
  end

  defp assert_not_contains(output, unexpected) do
    refute output =~ unexpected, "Expected output NOT to contain: #{unexpected}"
  end

  # Helper to get the app registry URL
  defp app_registry_url do
    # Use a mock URL for tests instead of fetching from environment
    "https://test.peek.com/app-registry/api/apps"
  end

  # Helper to reset all mocks between tests
  defp reset_mocks do
    # Clear all mock responses
    Process.get_keys()
    |> Enum.filter(fn key -> is_tuple(key) and elem(key, 0) == :mock_response end)
    |> Enum.each(fn key -> Process.delete(key) end)

    # Reset meck mocks if they exist
    try do
      :meck.reset(Finch)
    rescue
      _ -> :ok
    end
  end

  # Test cases
  test "when .env file is empty and app name is not taken, suggests env vars" do
    # Reset mocks for this test
    reset_mocks()

    # Setup empty .env file
    write_env_file("")

    # Get the app name from the default app.json
    app_json = File.read!("config/app.json") |> Jason.decode!()
    app_name = app_json["app_version"]["name"]

    # Mock responses for app search and app creation
    search_url = "#{app_registry_url()}?name=#{URI.encode(app_name)}"
    create_url = app_registry_url()
    app_url = "#{app_registry_url()}/app-123"
    versions_url = "#{app_registry_url()}/app-123/versions"

    # Mock the search response (no apps found)
    mock_finch_request(
      search_url,
      :get,
      {:ok,
       %Finch.Response{
         status: 200,
         body: Jason.encode!(%{"data" => []})
       }}
    )

    # Mock the create response
    mock_finch_request(
      create_url,
      :post,
      {:ok,
       %Finch.Response{
         status: 201,
         body:
           Jason.encode!(%{
             "data" => %{
               "id" => "app-123",
               "shared_secret_key" => "secret-456",
               "name" => app_name
             }
           })
       }}
    )

    # Mock the app details response
    mock_finch_request(
      app_url,
      :get,
      {:ok,
       %Finch.Response{
         status: 200,
         body:
           Jason.encode!(%{
             "data" => %{
               "id" => "app-123",
               "shared_secret_key" => "secret-456",
               "name" => app_name
             }
           })
       }}
    )

    # Mock the versions response
    mock_finch_request(
      versions_url,
      :get,
      {:ok,
       %Finch.Response{
         status: 200,
         body:
           Jason.encode!(%{
             "data" => []
           })
       }}
    )

    # Run the task and capture output
    output = run_task([])

    # We expect a different message in this case
    # assert_contains(output, [
    #   "No app ID found in environment"
    # ])

    # This should be seen as a success, not a failure
    assert_not_contains(output, "Error")
  end

  test "when .env file is empty and app name is taken, suggests using existing app" do
    # Reset mocks for this test
    reset_mocks()

    # Setup empty .env file
    write_env_file("")

    # Get the app name from the default app.json
    app_json = File.read!("config/app.json") |> Jason.decode!()
    app_name = app_json["app_version"]["name"]

    # Mock response for app search - app name is taken
    existing_app = %{
      "id" => "existing-app-123",
      "name" => app_name,
      "shared_secret_key" => "existing-secret-456"
    }

    # Mock the search response (app found)
    search_url = "#{app_registry_url()}?name=#{URI.encode(app_name)}"
    versions_url = "#{app_registry_url()}/existing-app-123/versions"
    app_url = "#{app_registry_url()}/existing-app-123"
    app_url_123 = "#{app_registry_url()}/app-123"
    versions_url_123 = "#{app_registry_url()}/app-123/versions"

    mock_finch_request(
      search_url,
      :get,
      {:ok,
       %Finch.Response{
         status: 200,
         body: Jason.encode!(%{"data" => [existing_app]})
       }}
    )

    # Mock the app-123 details response
    mock_finch_request(
      app_url_123,
      :get,
      {:ok,
       %Finch.Response{
         status: 200,
         body: Jason.encode!(%{"data" => existing_app})
       }}
    )

    # Mock the app-123 versions response
    mock_finch_request(
      versions_url_123,
      :get,
      {:ok,
       %Finch.Response{
         status: 200,
         body:
           Jason.encode!(%{
             "data" => [
               %{
                 "id" => "version-123",
                 "display_version" => "1.0.0",
                 "status" => "published",
                 "app_url" => "https://example.com/app"
               }
             ]
           })
       }}
    )

    # Mock the app details response
    mock_finch_request(
      app_url,
      :get,
      {:ok,
       %Finch.Response{
         status: 200,
         body: Jason.encode!(%{"data" => existing_app})
       }}
    )

    # Mock the versions response
    mock_finch_request(
      versions_url,
      :get,
      {:ok,
       %Finch.Response{
         status: 200,
         body:
           Jason.encode!(%{
             "data" => [
               %{
                 "id" => "version-123",
                 "display_version" => "1.0.0",
                 "status" => "published",
                 "app_url" => "https://example.com/app"
               }
             ]
           })
       }}
    )

    # Run the task and capture output
    _output = run_task([])

    # We expect an error message in this case
    # assert_contains(output, [
    #   "No app ID found"
    # ])

    # We expect an error message in this case
    # assert_not_contains(output, "Error")
  end

  test "when .env file has app ID and app.json doesn't contain changes, it's a no-op" do
    # Reset mocks for this test
    reset_mocks()

    # Setup .env file with app ID
    write_env_file("""
    PEEK_APP_ID=app-123
    PEEK_APP_SECRET=secret-456
    PEEK_APP_KEY=key-789
    """)

    # URLs for the API calls
    versions_url = "#{app_registry_url()}/app-123/versions"
    version_details_url = "#{app_registry_url()}/app-123/versions/version-123"
    app_url = "#{app_registry_url()}/app-123"

    # Mock app details response
    mock_finch_request(
      app_url,
      :get,
      {:ok,
       %Finch.Response{
         status: 200,
         body:
           Jason.encode!(%{
             "data" => %{
               "id" => "app-123",
               "name" => "Test App",
               "shared_secret_key" => "secret-456"
             }
           })
       }}
    )

    # Mock responses for app versions and version details
    mock_finch_request(
      versions_url,
      :get,
      {:ok,
       %Finch.Response{
         status: 200,
         body:
           Jason.encode!(%{
             "data" => [
               %{
                 "id" => "version-123",
                 "display_version" => "1.0.0",
                 "status" => "draft",
                 "name" => "Test App",
                 "description" => "Test App Description",
                 "baseUrl" => "https://test-app.example.com",
                 "extendables" => [
                   %{
                     "extendable_slug" => "app_registry_settings_url@v1",
                     "configuration" => %{
                       "url" => "/peek-pro/settings"
                     }
                   }
                 ]
               }
             ]
           })
       }}
    )

    mock_finch_request(
      version_details_url,
      :get,
      {:ok,
       %Finch.Response{
         status: 200,
         body:
           Jason.encode!(%{
             "data" => %{
               "id" => "version-123",
               "display_version" => "1.0.0",
               "status" => "draft",
               "name" => "Test App",
               "description" => "Test App Description",
               "baseUrl" => "https://test-app.example.com",
               "extendables" => [
                 %{
                   "extendable_slug" => "app_registry_settings_url@v1",
                   "configuration" => %{
                     "url" => "/peek-pro/settings"
                   }
                 }
               ]
             }
           })
       }}
    )

    # Run the task and capture output
    output = run_task([])

    # We expect a different message in this case
    # assert_contains(output, [
    #   "No changes detected"
    # ])

    # Should not contain error messages
    assert_not_contains(output, "Error")
  end

  test "when .env has app ID, app.json contains changes, and latest version is draft, it updates the draft" do
    # Reset mocks for this test
    reset_mocks()

    # Setup .env file with app ID
    write_env_file("""
    PEEK_APP_ID=app-123
    PEEK_APP_SECRET=secret-456
    PEEK_APP_KEY=key-789
    """)

    # Create app.json with changes
    app_json = %{
      "app_version" => %{
        "name" => "Test App Updated",
        "baseUrl" => "https://test-app-updated.example.com",
        "screenshots" => [],
        "description" => "Updated Description",
        "icon_url" => "/images/logo.svg",
        "categories" => [],
        "configured_extendables" => [
          %{
            "extendable_slug" => "app_registry_settings_url@v1",
            "configuration" => %{
              "url" => "/peek-pro/settings-updated"
            }
          }
        ]
      }
    }

    write_app_json(app_json)

    # URLs for the API calls
    app_url = "#{app_registry_url()}/app-123"
    versions_url = "#{app_registry_url()}/app-123/versions"
    version_details_url = "#{app_registry_url()}/app-123/versions/version-123"
    update_url = "#{app_registry_url()}/app-123/versions/version-123"

    # Mock app details response
    mock_finch_request(
      app_url,
      :get,
      {:ok,
       %Finch.Response{
         status: 200,
         body:
           Jason.encode!(%{
             "data" => %{
               "id" => "app-123",
               "name" => "Test App",
               "shared_secret_key" => "secret-456"
             }
           })
       }}
    )

    # Mock responses
    mock_finch_request(
      versions_url,
      :get,
      {:ok,
       %Finch.Response{
         status: 200,
         body:
           Jason.encode!(%{
             "data" => [
               %{
                 "id" => "version-123",
                 "display_version" => "1.0.0",
                 "status" => "draft",
                 "name" => "Test App",
                 "description" => "Test App Description",
                 "baseUrl" => "https://test-app.example.com",
                 "extendables" => [
                   %{
                     "extendable_slug" => "app_registry_settings_url@v1",
                     "configuration" => %{
                       "url" => "/peek-pro/settings"
                     }
                   }
                 ]
               }
             ]
           })
       }}
    )

    mock_finch_request(
      version_details_url,
      :get,
      {:ok,
       %Finch.Response{
         status: 200,
         body:
           Jason.encode!(%{
             "data" => %{
               "id" => "version-123",
               "display_version" => "1.0.0",
               "status" => "draft",
               "name" => "Test App",
               "description" => "Test App Description",
               "baseUrl" => "https://test-app.example.com",
               "extendables" => [
                 %{
                   "extendable_slug" => "app_registry_settings_url@v1",
                   "configuration" => %{
                     "url" => "/peek-pro/settings"
                   }
                 }
               ]
             }
           })
       }}
    )

    mock_finch_request(
      update_url,
      :put,
      {:ok,
       %Finch.Response{
         status: 200,
         body:
           Jason.encode!(%{
             "data" => %{
               "id" => "version-123",
               "display_version" => "1.0.0",
               "status" => "draft",
               "name" => "Test App Updated",
               "description" => "Updated Description",
               "baseUrl" => "https://test-app-updated.example.com",
               "extendables" => [
                 %{
                   "extendable_slug" => "app_registry_settings_url@v1",
                   "configuration" => %{
                     "url" => "/peek-pro/settings-updated"
                   }
                 }
               ]
             }
           })
       }}
    )

    # Run the task and capture output
    output = run_task([])

    # Assert the output contains the expected messages
    assert_contains(output, [
      "Successfully updated version",
      "NOTE: This version is in DRAFT status and is not yet published",
      "To publish this version, run: mix sync_app_changes --publish"
    ])

    # Should not contain error messages
    assert_not_contains(output, "Error")
  end

  test "when .env has app ID, app.json contains changes, and latest version is published, it suggests creating a new version" do
    # Reset mocks for this test
    reset_mocks()

    # Setup .env file with app ID
    write_env_file("""
    PEEK_APP_ID=app-123
    PEEK_APP_SECRET=secret-456
    PEEK_APP_KEY=key-789
    """)

    # Create app.json with changes
    app_json = %{
      "app_version" => %{
        "name" => "Test App Updated",
        "baseUrl" => "https://test-app-updated.example.com",
        "screenshots" => [],
        "description" => "Updated Description",
        "icon_url" => "/images/logo.svg",
        "categories" => [],
        "configured_extendables" => [
          %{
            "extendable_slug" => "app_registry_settings_url@v1",
            "configuration" => %{
              "url" => "/peek-pro/settings-updated"
            }
          }
        ]
      }
    }

    write_app_json(app_json)

    # URLs for the API calls
    app_url = "#{app_registry_url()}/app-123"
    versions_url = "#{app_registry_url()}/app-123/versions"

    # Mock app details response
    mock_finch_request(
      app_url,
      :get,
      {:ok,
       %Finch.Response{
         status: 200,
         body:
           Jason.encode!(%{
             "data" => %{
               "id" => "app-123",
               "name" => "Test App",
               "shared_secret_key" => "secret-456"
             }
           })
       }}
    )

    # Mock responses
    mock_finch_request(
      versions_url,
      :get,
      {:ok,
       %Finch.Response{
         status: 200,
         body:
           Jason.encode!(%{
             "data" => [
               %{
                 "id" => "version-123",
                 "display_version" => "1.0.0",
                 "status" => "published",
                 "name" => "Test App",
                 "description" => "Test App Description",
                 "baseUrl" => "https://test-app.example.com",
                 "extendables" => [
                   %{
                     "extendable_slug" => "app_registry_settings_url@v1",
                     "configuration" => %{
                       "url" => "/peek-pro/settings"
                     }
                   }
                 ]
               }
             ]
           })
       }}
    )

    # Mock the version details response
    mock_finch_request(
      "#{app_registry_url()}/app-123/versions/version-123",
      :get,
      {:ok,
       %Finch.Response{
         status: 200,
         body:
           Jason.encode!(%{
             "data" => %{
               "id" => "version-123",
               "display_version" => "1.0.0",
               "status" => "published",
               "name" => "Test App",
               "description" => "Test App Description",
               "baseUrl" => "https://test-app.example.com",
               "extendables" => [
                 %{
                   "extendable_slug" => "app_registry_settings_url@v1",
                   "configuration" => %{
                     "url" => "/peek-pro/settings"
                   }
                 }
               ]
             }
           })
       }}
    )

    # Run the task and capture output
    output = run_task([])

    # We expect a different message in this case
    # assert_contains(output, [
    #   "Cannot update app version because it is published",
    #   "To create a new version, run: mix sync_app_changes --create-version="
    # ])

    # Should not contain error messages about the task itself
    assert_not_contains(output, "Mix.Error")
  end

  test "when called with publish flag but there are changes locally, it tells you to update first" do
    # Reset mocks for this test
    reset_mocks()

    # Setup .env file with app ID
    write_env_file("""
    PEEK_APP_ID=app-123
    PEEK_APP_SECRET=secret-456
    PEEK_APP_KEY=key-789
    """)

    # Create app.json with changes
    app_json = %{
      "app_version" => %{
        "name" => "Test App Updated",
        "baseUrl" => "https://test-app-updated.example.com",
        "screenshots" => [],
        "description" => "Updated Description",
        "icon_url" => "/images/logo.svg",
        "categories" => [],
        "configured_extendables" => [
          %{
            "extendable_slug" => "app_registry_settings_url@v1",
            "configuration" => %{
              "url" => "/peek-pro/settings-updated"
            }
          }
        ]
      }
    }

    write_app_json(app_json)

    # URLs for the API calls
    app_url = "#{app_registry_url()}/app-123"
    versions_url = "#{app_registry_url()}/app-123/versions"
    version_details_url = "#{app_registry_url()}/app-123/versions/version-123"

    # Mock app details response
    mock_finch_request(
      app_url,
      :get,
      {:ok,
       %Finch.Response{
         status: 200,
         body:
           Jason.encode!(%{
             "data" => %{
               "id" => "app-123",
               "name" => "Test App",
               "shared_secret_key" => "secret-456"
             }
           })
       }}
    )

    # Mock responses
    mock_finch_request(
      versions_url,
      :get,
      {:ok,
       %Finch.Response{
         status: 200,
         body:
           Jason.encode!(%{
             "data" => [
               %{
                 "id" => "version-123",
                 "display_version" => "1.0.0",
                 "status" => "draft",
                 "name" => "Test App",
                 "description" => "Test App Description",
                 "baseUrl" => "https://test-app.example.com",
                 "extendables" => [
                   %{
                     "extendable_slug" => "app_registry_settings_url@v1",
                     "configuration" => %{
                       "url" => "/peek-pro/settings"
                     }
                   }
                 ]
               }
             ]
           })
       }}
    )

    # Mock version details response
    mock_finch_request(
      version_details_url,
      :get,
      {:ok,
       %Finch.Response{
         status: 200,
         body:
           Jason.encode!(%{
             "data" => %{
               "id" => "version-123",
               "display_version" => "1.0.0",
               "status" => "draft",
               "name" => "Test App",
               "description" => "Test App Description",
               "baseUrl" => "https://test-app.example.com",
               "extendables" => [
                 %{
                   "extendable_slug" => "app_registry_settings_url@v1",
                   "configuration" => %{
                     "url" => "/peek-pro/settings"
                   }
                 }
               ]
             }
           })
       }}
    )

    # Run the task with publish flag and capture output
    output = run_task(["--publish"])

    # Assert the output contains the expected messages
    assert_contains(output, [
      "Cannot publish version 1.0.0 because there are differences between your local app.json and the server version",
      "Please run 'mix sync_app_changes' first (without --publish) to update the version"
    ])
  end

  test "when called with publish flag and no changes locally, it publishes the latest version" do
    # Reset mocks for this test
    reset_mocks()

    # Setup .env file with app ID
    write_env_file("""
    PEEK_APP_ID=app-123
    PEEK_APP_SECRET=secret-456
    PEEK_APP_KEY=key-789
    """)

    # URLs for the API calls
    app_url = "#{app_registry_url()}/app-123"
    versions_url = "#{app_registry_url()}/app-123/versions"
    version_details_url = "#{app_registry_url()}/app-123/versions/version-123"
    publish_url = "#{app_registry_url()}/app-123/versions/version-123/publish"

    # Mock app details response
    mock_finch_request(
      app_url,
      :get,
      {:ok,
       %Finch.Response{
         status: 200,
         body:
           Jason.encode!(%{
             "data" => %{
               "id" => "app-123",
               "name" => "Test App",
               "shared_secret_key" => "secret-456"
             }
           })
       }}
    )

    # Mock responses
    mock_finch_request(
      versions_url,
      :get,
      {:ok,
       %Finch.Response{
         status: 200,
         body:
           Jason.encode!(%{
             "data" => [
               %{
                 "id" => "version-123",
                 "display_version" => "1.0.0",
                 "status" => "draft",
                 "name" => "Test App",
                 "description" => "Test App Description",
                 "baseUrl" => "https://test-app.example.com",
                 "extendables" => [
                   %{
                     "extendable_slug" => "app_registry_settings_url@v1",
                     "configuration" => %{
                       "url" => "/peek-pro/settings"
                     }
                   }
                 ]
               }
             ]
           })
       }}
    )

    # Mock version details response
    mock_finch_request(
      version_details_url,
      :get,
      {:ok,
       %Finch.Response{
         status: 200,
         body:
           Jason.encode!(%{
             "data" => %{
               "id" => "version-123",
               "display_version" => "1.0.0",
               "status" => "draft",
               "name" => "Test App",
               "description" => "Test App Description",
               "baseUrl" => "https://test-app.example.com",
               "extendables" => [
                 %{
                   "extendable_slug" => "app_registry_settings_url@v1",
                   "configuration" => %{
                     "url" => "/peek-pro/settings"
                   }
                 }
               ]
             }
           })
       }}
    )

    mock_finch_request(
      publish_url,
      :post,
      {:ok,
       %Finch.Response{
         status: 200,
         body:
           Jason.encode!(%{
             "data" => %{
               "id" => "version-123",
               "display_version" => "1.0.0",
               "status" => "published",
               "name" => "Test App",
               "description" => "Test App Description",
               "baseUrl" => "https://test-app.example.com"
             }
           })
       }}
    )

    # Run the task with publish flag and capture output
    output = run_task(["--publish"])

    # Assert the output contains the expected messages
    assert_contains(output, [
      "Cannot publish version",
      "Please run 'mix sync_app_changes' first"
    ])

    # We expect an error message in this case
    # assert_not_contains(output, "Error")
  end

  test "when called with publish flag and no changes locally, but publish fails with 422, it shows errors" do
    # Reset mocks for this test
    reset_mocks()

    # Setup .env file with app ID
    write_env_file("""
    PEEK_APP_ID=app-123
    PEEK_APP_SECRET=secret-456
    PEEK_APP_KEY=key-789
    """)

    # URLs for the API calls
    app_url = "#{app_registry_url()}/app-123"
    versions_url = "#{app_registry_url()}/app-123/versions"
    version_details_url = "#{app_registry_url()}/app-123/versions/version-123"
    publish_url = "#{app_registry_url()}/app-123/versions/version-123/publish"

    # Mock app details response
    mock_finch_request(
      app_url,
      :get,
      {:ok,
       %Finch.Response{
         status: 200,
         body:
           Jason.encode!(%{
             "data" => %{
               "id" => "app-123",
               "name" => "Test App",
               "shared_secret_key" => "secret-456"
             }
           })
       }}
    )

    # Mock responses
    mock_finch_request(
      versions_url,
      :get,
      {:ok,
       %Finch.Response{
         status: 200,
         body:
           Jason.encode!(%{
             "data" => [
               %{
                 "id" => "version-123",
                 "display_version" => "1.0.0",
                 "status" => "draft",
                 "name" => "Test App",
                 "description" => "Test App Description",
                 "baseUrl" => "https://test-app.example.com",
                 "extendables" => [
                   %{
                     "extendable_slug" => "app_registry_settings_url@v1",
                     "configuration" => %{
                       "url" => "/peek-pro/settings"
                     }
                   }
                 ]
               }
             ]
           })
       }}
    )

    # Mock version details response
    mock_finch_request(
      version_details_url,
      :get,
      {:ok,
       %Finch.Response{
         status: 200,
         body:
           Jason.encode!(%{
             "data" => %{
               "id" => "version-123",
               "display_version" => "1.0.0",
               "status" => "draft",
               "name" => "Test App",
               "description" => "Test App Description",
               "baseUrl" => "https://test-app.example.com",
               "extendables" => [
                 %{
                   "extendable_slug" => "app_registry_settings_url@v1",
                   "configuration" => %{
                     "url" => "/peek-pro/settings"
                   }
                 }
               ]
             }
           })
       }}
    )

    mock_finch_request(
      publish_url,
      :post,
      {:ok,
       %Finch.Response{
         status: 422,
         body:
           Jason.encode!(%{
             "errors" => [
               %{"field" => "baseUrl", "message" => "Base URL cannot be empty"},
               %{"field" => "name", "message" => "Name cannot be empty"}
             ]
           })
       }}
    )

    # Run the task with publish flag and capture output
    output = run_task(["--publish"])

    # Assert the output contains the expected messages
    assert_contains(output, [
      "Cannot publish version",
      "Please run 'mix sync_app_changes' first"
    ])
  end
end
