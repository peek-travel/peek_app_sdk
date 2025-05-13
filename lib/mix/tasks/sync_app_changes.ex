defmodule Mix.Tasks.SyncAppChanges do
  @moduledoc """
  Synchronizes app changes with the Peek Pro App Registry.

  This task reads the app configuration from config/app.json and synchronizes
  it with the Peek Pro App Registry. It can register a new app, update an existing
  app version, create a new app version, and publish the app version.

  ## Options

    * `--info` - Just display information about the app without making changes
    * `--publish` - Publish the app version after updating it
    * `--create-version` - Create a new app version with the specified display version
    * `--verbose` - Show detailed logging information

  ## Examples

      $ mix sync_app_changes
      $ mix sync_app_changes --verbose
      $ mix sync_app_changes --info
      $ mix sync_app_changes --publish
      $ mix sync_app_changes --create-version="1.0.0"
      $ mix sync_app_changes --create-version="1.0.0" --publish

  """
  use Mix.Task
  require Logger

  @shortdoc "Synchronizes app changes with the Peek Pro App Registry"

  # Load environment variables from .env file
  defp load_env_vars do
    env_path = Path.join(File.cwd!(), ".env")

    if File.exists?(env_path) do
      # Load the .env file and set environment variables
      content = File.read!(env_path)

      # Parse the .env file manually
      content
      |> String.split("\n")
      |> Enum.filter(fn line ->
        # Filter out comments and empty lines
        line = String.trim(line)
        line != "" && !String.starts_with?(line, "#")
      end)
      |> Enum.each(fn line ->
        case Regex.run(~r/^([A-Za-z0-9_]+)=["']?([^"']*)["']?$/, String.trim(line)) do
          [_, key, value] -> System.put_env(key, value)
          _ -> nil
        end
      end)
    end
  end

  defp app_registry_url do
    load_env_vars()

    System.get_env("PEEK_APP_REGISTRY_URL") ||
      raise "PEEK_APP_REGISTRY_URL environment variable is not set. Please add it to your .env file."
  end

  defp auth_token do
    load_env_vars()

    System.get_env("PEEK_APP_REGISTRY_AUTH_TOKEN") ||
      raise "PEEK_APP_REGISTRY_AUTH_TOKEN environment variable is not set. Please add it to your .env file."
  end

  # Logging levels
  @log_level_info :info
  @log_level_debug :debug
  @log_level_essential :essential

  # Helper function to calculate the next version
  defp calculate_next_version(version) do
    case String.split(version, ".") do
      [major, minor, patch] ->
        case Integer.parse(patch) do
          {patch_num, ""} -> "#{major}.#{minor}.#{patch_num + 1}"
          _ -> nil
        end

      _ ->
        nil
    end
  end

  # Helper function for logging based on verbosity
  defp log(level, message, verbose) do
    cond do
      # Always log errors
      level == :error ->
        Logger.error(message)

      # Always log essential messages
      level == @log_level_essential ->
        # Use notice level for essential messages to make them stand out
        IO.puts(message)

      # Log info and debug messages only in verbose mode
      verbose && level == @log_level_info ->
        Logger.info(message)

      verbose && level == @log_level_debug ->
        Logger.debug(message)

      # Don't log in non-verbose mode
      true ->
        :ok
    end
  end

  @impl Mix.Task
  def run(args) do
    # Parse options
    {opts, _, _} =
      OptionParser.parse(args,
        strict: [
          info: :boolean,
          publish: :boolean,
          create_version: :string,
          verbose: :boolean
        ]
      )

    info_only = Keyword.get(opts, :info, false)
    publish = Keyword.get(opts, :publish, false)
    create_version = Keyword.get(opts, :create_version)
    verbose = Keyword.get(opts, :verbose, false)

    # Start Finch
    {:ok, _} = Application.ensure_all_started(:finch)
    {:ok, _} = Finch.start_link(name: SyncAppFinch)

    # Read app.json
    app_name = get_app_name(verbose)

    log(@log_level_info, "Starting app synchronization...", verbose)

    cond do
      info_only ->
        # Just get info about the app
        get_app_info(app_name, verbose)

      publish ->
        # Publish-only mode - just publish the latest draft version without updating
        publish_only(app_name, verbose)

      true ->
        # Get the app ID from environment variables
        app_id = get_app_id_from_env(verbose)

        if !app_id do
          # No app ID in environment, register a new app
          log(
            @log_level_essential,
            "No app ID found in environment or .env file. Registering a new app...",
            verbose
          )

          {registered, found_app_id, _version_id} = register_app(app_name, verbose)

          # Check if we found or registered an app
          if registered && found_app_id do
            # This is a newly registered app (if we found an existing app, we would have exited already)
            System.put_env("PEEK_APP_ID", found_app_id)
          else
            Mix.raise(
              "Failed to find or register app. Please check the logs for more information."
            )
          end
        end

        # Get the final app ID
        app_id = get_app_id_from_env(verbose)

        if app_id do
          if create_version do
            # Create a new version with the specified display version
            {_created, _version_id} = create_app_version(app_id, create_version, verbose)
          else
            # App exists, update the latest version
            {_updated, _version_id, needs_new_version, current_display_version} =
              update_app_version(app_id, app_name, verbose)

            if needs_new_version do
              # Calculate next patch version if possible
              next_version = calculate_next_version(current_display_version)
              suggestion = if next_version, do: next_version, else: "X.Y.Z"

              Logger.error(
                "Cannot update app version because it is published (current: #{current_display_version})."
              )

              Logger.error(
                "To create a new version, run: mix sync_app_changes --create-version=\"#{suggestion}\""
              )
            end
          end
        else
          Mix.raise("Failed to find or register app. Please check the logs for more information.")
        end
    end

    log(@log_level_info, "App synchronization completed.", verbose)
  end

  defp publish_only(app_name, verbose) do
    # Get the app ID from environment variables
    app_id = get_app_id_from_env(verbose)

    if !app_id do
      # No app ID in environment, cannot publish
      log(
        @log_level_essential,
        "No app ID found in environment or .env file. Please run without --publish first to register the app.",
        verbose
      )

      Mix.raise(
        "Cannot find app ID for '#{app_name}'. Please run without --publish first to register the app."
      )
    end

    # Get the final app ID
    final_app_id = get_app_id_from_env(verbose)

    # Get the latest version
    log(@log_level_info, "Getting app versions for app ID: #{final_app_id}...", verbose)

    request =
      Finch.build(
        :get,
        "#{app_registry_url()}/#{final_app_id}/versions",
        [
          {"Authorization", "Bearer #{auth_token()}"},
          {"Content-Type", "application/json"},
          {"User-Agent", "phoenix_starter_kit/1.0.0"}
        ]
      )

    case Finch.request(request, SyncAppFinch) do
      {:ok, %Finch.Response{status: 200, body: response_body}} ->
        case Jason.decode(response_body) do
          {:ok, %{"data" => []}} ->
            Mix.raise("No app versions found for app ID: #{final_app_id}")

          {:ok, %{"data" => [latest_version | _]}} ->
            # Check if the latest version is in draft status
            display_version = latest_version["display_version"] || "0.0.0"

            if latest_version["status"] != "draft" do
              Mix.raise(
                "Cannot publish version #{display_version} because it is already published."
              )
            end

            # Check if there are differences between app.json and the latest version
            app_json = read_app_json(verbose)
            transformed_json = transform_app_json(app_json)
            app_version = transformed_json["app_version"]

            # Compare with the latest version
            changes = detect_changes(app_version, latest_version)

            if changes != [] do
              Mix.raise(
                "Cannot publish version #{display_version} because there are differences between your local app.json and the server version.\n" <>
                  "Please run 'mix sync_app_changes' first (without --publish) to update the version."
              )
            end

            # Publish the version
            success = publish_app_version(final_app_id, latest_version["id"], verbose)

            if !success do
              Mix.raise("Failed to publish app version. See errors above.")
            end

          {:ok, response} ->
            Mix.raise("Unexpected response format: #{inspect(response)}")

          {:error, error} ->
            Mix.raise("Error parsing response: #{inspect(error)}")
        end

      {:ok, %Finch.Response{status: status, body: response_body}} ->
        Mix.raise("Failed to get app versions. Status: #{status}, Response: #{response_body}")

      {:error, error} ->
        Mix.raise("Error getting app versions: #{inspect(error)}")
    end
  end

  defp publish_app_version(app_id, version_id, verbose) do
    log(@log_level_info, "Publishing app version...", verbose)

    # Create an empty JSON body
    body = "{}"

    request =
      Finch.build(
        :post,
        "#{app_registry_url()}/#{app_id}/versions/#{version_id}/publish",
        [
          {"Authorization", "Bearer #{auth_token()}"},
          {"Content-Type", "application/json"},
          {"Content-Length", "2"},
          {"User-Agent", "phoenix_starter_kit/1.0.0"}
        ],
        body
      )

    case Finch.request(request, SyncAppFinch) do
      {:ok, %Finch.Response{status: status, body: response_body}} when status in 200..299 ->
        # Try to extract the version number from the response
        display_version =
          case Jason.decode(response_body) do
            {:ok, %{"data" => %{"display_version" => version}}} -> version
            _ -> nil
          end

        if display_version do
          log(@log_level_essential, "Successfully published version #{display_version}.", verbose)
        else
          log(@log_level_essential, "Successfully published app version.", verbose)
        end

        log(@log_level_debug, "Response: #{response_body}", verbose)
        true

      {:ok, %Finch.Response{status: status, body: response_body}} ->
        Logger.error("Failed to publish app version. Status: #{status}")
        Logger.error("Response: #{response_body}")
        false

      {:error, error} ->
        Logger.error("Error publishing app version: #{inspect(error)}")
        false
    end
  end

  defp register_app(app_name, verbose) do
    # Prepare request body
    body =
      Jason.encode!(
        %{
          app: %{
            name: app_name
          }
        }
        |> IO.inspect()
      )

    # Make the request
    request =
      Finch.build(
        :post,
        app_registry_url() |> IO.inspect(),
        [
          {"Authorization", "Bearer #{auth_token()}"},
          {"Content-Type", "application/json"},
          {"User-Agent", "phoenix_starter_kit/1.0.0"}
        ],
        body
      )

    case Finch.request(request, SyncAppFinch) do
      {:ok, %Finch.Response{status: status, body: response_body}} when status in 200..299 ->
        log(
          @log_level_essential,
          "Successfully registered app '#{app_name}' with the Peek Pro App Registry",
          verbose
        )

        log(@log_level_debug, "Response: #{response_body}", verbose)

        # Parse the response to get the app ID and shared secret
        case Jason.decode(response_body) do
          # Handle response format with "data" wrapper
          {:ok, %{"data" => %{"id" => app_id, "shared_secret_key" => shared_secret}}} ->
            # Get the app URL from the first version if available
            app_url = get_app_url_from_versions(app_id, verbose)

            # Always update .env file for newly registered apps
            update_env_file(app_id, shared_secret, verbose, app_url)

            # Return success with app_id and version_id
            {true, app_id, nil}

          # Handle response format with "data" wrapper but no shared secret
          {:ok, %{"data" => %{"id" => app_id}}} ->
            # Get the app URL from the first version if available
            app_url = get_app_url_from_versions(app_id, verbose)

            # Always update .env file for newly registered apps
            update_env_file(app_id, nil, verbose, app_url)

            # Return success with app_id and version_id
            {true, app_id, nil}

          # Handle direct response format (no "data" wrapper)
          {:ok, %{"id" => app_id, "shared_secret_key" => shared_secret}} ->
            # Get the app URL from the first version if available
            app_url = get_app_url_from_versions(app_id, verbose)

            # Always update .env file for newly registered apps
            update_env_file(app_id, shared_secret, verbose, app_url)

            # Return success with app_id and version_id
            {true, app_id, nil}

          # Handle direct response format with no shared secret
          {:ok, %{"id" => app_id}} ->
            # Get the app URL from the first version if available
            app_url = get_app_url_from_versions(app_id, verbose)

            # Always update .env file for newly registered apps
            update_env_file(app_id, nil, verbose, app_url)

            # Return success with app_id and version_id
            {true, app_id, nil}

          _ ->
            log(
              @log_level_essential,
              "App registered successfully, but couldn't extract app ID from response.",
              verbose
            )

            log(@log_level_info, "Response: #{response_body}", verbose)

            log(
              @log_level_info,
              "Please run 'mix sync_app_changes --info' to get the app details.",
              verbose
            )

            # Return failure
            {false, nil, nil}
        end

      {:ok, %Finch.Response{status: 422, body: response_body}} ->
        Logger.error("Failed to register app. Status: 422")
        Logger.error("Response: #{response_body}")
        log(@log_level_essential, "App name '#{app_name}' is already taken.", verbose)

        # If the app name is already taken, try to find the app by name
        log(@log_level_essential, "Searching for app by name...", verbose)

        # Search for the app by name
        search_request =
          Finch.build(
            :get,
            "#{app_registry_url()}?name=#{URI.encode(app_name)}",
            [
              {"Authorization", "Bearer #{auth_token()}"},
              {"Content-Type", "application/json"},
              {"User-Agent", "phoenix_starter_kit/1.0.0"}
            ]
          )

        case Finch.request(search_request, SyncAppFinch) do
          {:ok, %Finch.Response{status: 200, body: search_response_body}} ->
            case Jason.decode(search_response_body) do
              {:ok, %{"data" => []}} ->
                # No app found, this is strange since the name is already taken
                log(@log_level_essential, "No app found with name '#{app_name}'.", verbose)

                log(
                  @log_level_essential,
                  "Use --info to get information about the existing app",
                  verbose
                )

                # Return failure
                {false, nil, nil}

              {:ok, %{"data" => apps}} when is_list(apps) and length(apps) > 0 ->
                # Find the exact match for the app name
                case Enum.find(apps, fn app -> app["name"] == app_name end) do
                  nil ->
                    # If no exact match, use the first app in the list
                    app = hd(apps)

                    log(
                      @log_level_essential,
                      "No exact match found for '#{app_name}'. Using first result:",
                      verbose
                    )

                    log(@log_level_essential, "App Information:", verbose)
                    log(@log_level_essential, "  ID: #{app["id"]}", verbose)
                    log(@log_level_essential, "  Name: #{app["name"]}", verbose)

                    # Get the shared secret and app URL if available
                    shared_secret = Map.get(app, "shared_secret_key")
                    app_url = get_app_url_from_versions(app["id"], verbose)

                    # Provide instructions to update .env file instead of updating it
                    suggest_env_updates(app["id"], shared_secret, app_url, verbose)

                    # Return success with app_id instead of exiting
                    {true, app["id"], nil}

                  app ->
                    # Use the exact match
                    log(@log_level_essential, "Found app: #{app["name"]} (#{app["id"]})", verbose)

                    # Get the shared secret and app URL if available
                    shared_secret = Map.get(app, "shared_secret_key")
                    app_url = get_app_url_from_versions(app["id"], verbose)

                    # Provide instructions to update .env file instead of updating it
                    suggest_env_updates(app["id"], shared_secret, app_url, verbose)

                    # Return success with app_id instead of exiting
                    {true, app["id"], nil}
                end

              _ ->
                # Error parsing response
                log(@log_level_essential, "Error parsing response.", verbose)

                log(
                  @log_level_essential,
                  "Use --info to get information about the existing app",
                  verbose
                )

                # Return failure
                {false, nil, nil}
            end

          _ ->
            # Error making request
            log(@log_level_essential, "Error making request.", verbose)

            log(
              @log_level_essential,
              "Use --info to get information about the existing app",
              verbose
            )

            # Return failure
            {false, nil, nil}
        end

      {:ok, %Finch.Response{status: status, body: response_body}} ->
        Logger.error("Failed to register app. Status: #{status}")
        Logger.error("Response: #{response_body}")

        # Return failure
        {false, nil, nil}

      {:error, error} ->
        Logger.error("Error making request: #{inspect(error)}")

        # Return failure
        {false, nil, nil}
    end
  end

  defp get_app_info(app_name, verbose) do
    # Check for app ID in environment variables
    app_id = get_app_id_from_env(verbose)

    if !app_id do
      # No app ID in environment, register a new app
      log(
        @log_level_essential,
        "No app ID found in environment or .env file. Registering a new app...",
        verbose
      )

      {registered, app_id, _version_id} = register_app(app_name, verbose)

      # If registration returned success but with an app ID, it means the app was found by name
      # This happens when the app name is already taken
      if registered && app_id do
        # App was found by name, continue with the app ID
        log(@log_level_essential, "Using existing app with ID: #{app_id}", verbose)
      else
        # If registration failed for other reasons, raise an error
        Mix.raise("Failed to find or register app. Please check the logs for more information.")
      end
    end

    # Get the final app ID
    final_app_id = get_app_id_from_env(verbose)

    # Now get the app info using the app ID
    log(@log_level_essential, "Getting information for app ID: #{final_app_id}...", verbose)

    request =
      Finch.build(
        :get,
        "#{app_registry_url()}/#{final_app_id}",
        [
          {"Authorization", "Bearer #{auth_token()}"},
          {"Content-Type", "application/json"},
          {"User-Agent", "phoenix_starter_kit/1.0.0"}
        ]
      )

    case Finch.request(request, SyncAppFinch) do
      {:ok, %Finch.Response{status: 200, body: response_body}} ->
        log(@log_level_debug, "Response body: #{response_body}", verbose)

        case Jason.decode(response_body) do
          # Handle array response format
          {:ok, %{"data" => []}} ->
            log(@log_level_essential, "No app found with name '#{app_name}'", verbose)

          # Handle array response format with data
          {:ok, %{"data" => apps}} when is_list(apps) and length(apps) > 0 ->
            # Find the exact match for the app name
            case Enum.find(apps, fn app -> app["name"] == app_name end) do
              nil ->
                # If no exact match, use the first app in the list
                app = hd(apps)

                log(
                  @log_level_essential,
                  "No exact match found for '#{app_name}'. Using first result:",
                  verbose
                )

                log(@log_level_essential, "App Information:", verbose)
                log(@log_level_essential, "  ID: #{app["id"]}", verbose)
                log(@log_level_essential, "  Name: #{app["name"]}", verbose)

                shared_secret =
                  if Map.has_key?(app, "shared_secret_key") do
                    secret = app["shared_secret_key"]
                    log(@log_level_info, "  Shared Secret Key: #{secret}", verbose)
                    secret
                  else
                    nil
                  end

                log(@log_level_info, "\nAdd this to your config/runtime.exs:", verbose)
                log(@log_level_info, "    peek_app_id: \"#{app["id"]}\",", verbose)

                # Only update .env file if it's a new app (first time)
                if !get_app_id_from_env(verbose) do
                  update_env_file(app["id"], shared_secret, verbose)
                end

              app ->
                # Use the exact match
                log(@log_level_essential, "App Information:", verbose)
                log(@log_level_essential, "  ID: #{app["id"]}", verbose)
                log(@log_level_essential, "  Name: #{app["name"]}", verbose)

                shared_secret =
                  if Map.has_key?(app, "shared_secret_key") do
                    secret = app["shared_secret_key"]
                    log(@log_level_info, "  Shared Secret Key: #{secret}", verbose)
                    secret
                  else
                    nil
                  end

                log(@log_level_info, "\nAdd this to your config/runtime.exs:", verbose)
                log(@log_level_info, "    peek_app_id: \"#{app["id"]}\",", verbose)

                # Only update .env file if it's a new app (first time)
                if !get_app_id_from_env(verbose) do
                  update_env_file(app["id"], shared_secret, verbose)
                end

                # Get the app versions
                get_app_versions(app["id"], verbose)
            end

          # Handle direct object response format
          {:ok, %{"data" => app}} when is_map(app) ->
            log(@log_level_essential, "App Information:", verbose)
            log(@log_level_essential, "  ID: #{app["id"]}", verbose)
            log(@log_level_essential, "  Name: #{app["name"]}", verbose)

            shared_secret =
              if Map.has_key?(app, "shared_secret_key") do
                secret = app["shared_secret_key"]
                log(@log_level_info, "  Shared Secret Key: #{secret}", verbose)
                secret
              else
                nil
              end

            log(@log_level_info, "\nAdd this to your config/runtime.exs:", verbose)
            log(@log_level_info, "    peek_app_id: \"#{app["id"]}\",", verbose)

            # Only update .env file if it's a new app (first time)
            if !get_app_id_from_env(verbose) do
              update_env_file(app["id"], shared_secret, verbose)
            end

            # Get the app versions
            get_app_versions(app["id"], verbose)

          {:ok, response} ->
            Logger.error("Unexpected response format: #{inspect(response)}")

            log(
              @log_level_essential,
              "Please check the API documentation for the correct format.",
              verbose
            )

          {:error, error} ->
            Logger.error("Error parsing response: #{inspect(error)}")
        end

      {:ok, %Finch.Response{status: status, body: response_body}} ->
        Logger.error("Failed to get app info. Status: #{status}")
        Logger.error("Response: #{response_body}")

      {:error, error} ->
        Logger.error("Error getting app info: #{inspect(error)}")
    end
  end

  defp get_app_versions(app_id, verbose) do
    log(@log_level_info, "Getting app versions for app ID: #{app_id}...", verbose)

    request =
      Finch.build(
        :get,
        "#{app_registry_url()}/#{app_id}/versions",
        [
          {"Authorization", "Bearer #{auth_token()}"},
          {"Content-Type", "application/json"},
          {"User-Agent", "phoenix_starter_kit/1.0.0"}
        ]
      )

    case Finch.request(request, SyncAppFinch) do
      {:ok, %Finch.Response{status: 200, body: response_body}} ->
        log(@log_level_debug, "Response body: #{response_body}", verbose)

        case Jason.decode(response_body) do
          {:ok, %{"data" => []}} ->
            log(@log_level_essential, "No app versions found for app ID: #{app_id}", verbose)

          {:ok, %{"data" => versions}} when is_list(versions) ->
            log(@log_level_essential, "App Versions:", verbose)

            Enum.each(versions, fn version ->
              log(@log_level_essential, "  ID: #{version["id"]}", verbose)
              log(@log_level_info, "  Name: #{version["name"]}", verbose)
              log(@log_level_essential, "  Status: #{version["status"]}", verbose)
              log(@log_level_info, "  Description: #{version["description"]}", verbose)
              log(@log_level_info, "  Base URL: #{version["base_url"]}", verbose)
              log(@log_level_info, "  Build Number: #{version["build_number"]}", verbose)

              log(
                @log_level_essential,
                "  Display Version: #{version["display_version"]}",
                verbose
              )

              log(
                @log_level_info,
                "  Shared Secret Key: #{version["shared_secret_key"]}",
                verbose
              )

              log(@log_level_essential, "  App URL: #{version["app_url"]}", verbose)
              log(@log_level_info, "", verbose)
            end)

          {:ok, response} ->
            Logger.error("Unexpected response format: #{inspect(response)}")

          {:error, error} ->
            Logger.error("Error parsing response: #{inspect(error)}")
        end

      {:ok, %Finch.Response{status: status, body: response_body}} ->
        Logger.error("Failed to get app versions. Status: #{status}")
        Logger.error("Response: #{response_body}")

      {:error, error} ->
        Logger.error("Error getting app versions: #{inspect(error)}")
    end
  end

  defp suggest_env_updates(app_id, shared_secret, app_url, verbose) do
    log(@log_level_essential, "\nAdd the following values to your .env file:", verbose)
    log(@log_level_essential, "PEEK_APP_ID=\"#{app_id}\"", verbose)

    if shared_secret do
      log(@log_level_essential, "PEEK_APP_SECRET=\"#{shared_secret}\"", verbose)
    end

    if app_url do
      log(@log_level_essential, "EMBEDDED_APP_URL=\"#{app_url}\"", verbose)
    end

    # Return true to indicate this is an existing app that was found
    true
  end

  # Helper function to get app URL from versions
  defp get_app_url_from_versions(app_id, _verbose) do
    request =
      Finch.build(
        :get,
        "#{app_registry_url()}/#{app_id}/versions",
        [
          {"Authorization", "Bearer #{auth_token()}"},
          {"Content-Type", "application/json"},
          {"User-Agent", "phoenix_starter_kit/1.0.0"}
        ]
      )

    case Finch.request(request, SyncAppFinch) do
      {:ok, %Finch.Response{status: 200, body: response_body}} ->
        case Jason.decode(response_body) do
          {:ok, %{"data" => [latest_version | _]}} when is_map(latest_version) ->
            Map.get(latest_version, "app_url")

          _ ->
            nil
        end

      _ ->
        nil
    end
  end

  defp update_env_file(app_id, shared_secret, verbose, app_url \\ nil) do
    # Instead of updating the file, just suggest the changes
    suggest_env_updates(app_id, shared_secret, app_url, verbose)

    # Log that we're not actually updating the file
    log(
      @log_level_essential,
      "NOTE: The .env file was NOT modified. Please update it manually with the values above.",
      verbose
    )
  end

  # These functions are kept as comments for reference but are no longer used
  # since we now only suggest changes to the .env file rather than making them.

  # defp update_existing_env_file(env_path, app_id, shared_secret, verbose, app_url) do
  #   log(@log_level_info, "Updating existing .env file with new values...", verbose)
  #   # ... implementation removed ...
  # end

  # defp create_new_env_file(env_path, app_id, shared_secret, verbose, app_url) do
  #   log(@log_level_essential, "Creating new .env file with Peek App configuration...", verbose)
  #   # ... implementation removed ...
  # end

  defp transform_app_json(app_json) do
    # Get the app_version from the JSON
    app_version = app_json["app_version"]

    if app_version do
      # Transform the app_version to match the API's expected format
      transformed_app_version = %{}

      # Copy all fields from app_version
      transformed_app_version =
        Enum.reduce(app_version, transformed_app_version, fn {key, value}, acc ->
          # Convert camelCase keys to snake_case
          new_key =
            case key do
              "baseUrl" -> "base_url"
              "iconUrl" -> "icon_url"
              _ -> key
            end

          Map.put(acc, new_key, value)
        end)

      # Return the transformed JSON
      %{"app_version" => transformed_app_version}
    else
      # If there's no app_version, return the original JSON
      app_json
    end
  end

  defp update_app_version(app_id, _app_name, verbose) do
    # Get the app versions
    log(@log_level_info, "Getting app versions for app ID: #{app_id}...", verbose)

    request =
      Finch.build(
        :get,
        "#{app_registry_url()}/#{app_id}/versions",
        [
          {"Authorization", "Bearer #{auth_token()}"},
          {"Content-Type", "application/json"},
          {"User-Agent", "phoenix_starter_kit/1.0.0"}
        ]
      )

    case Finch.request(request, SyncAppFinch) do
      {:ok, %Finch.Response{status: 200, body: response_body}} ->
        log(@log_level_debug, "Response body: #{response_body}", verbose)

        case Jason.decode(response_body) do
          {:ok, %{"data" => []}} ->
            Logger.error("No app versions found for app ID: #{app_id}")
            {false, nil, false, nil}

          {:ok, %{"data" => [latest_version | _]}} ->
            log(@log_level_info, "Latest app version:", verbose)
            log(@log_level_info, "  ID: #{latest_version["id"]}", verbose)
            log(@log_level_info, "  Status: #{latest_version["status"]}", verbose)

            display_version = latest_version["display_version"] || "0.0.0"

            if latest_version["status"] == "draft" do
              # Update the latest app version
              updated = update_app_version_with_id(app_id, latest_version["id"], verbose)
              {updated, latest_version["id"], false, display_version}
            else
              # Cannot update published version directly
              # First check if there are any changes to apply
              app_json = read_app_json(verbose)
              transformed_json = transform_app_json(app_json)
              app_version = transformed_json["app_version"]

              # Compare with the latest version
              changes = detect_changes(app_version, latest_version)

              if changes == [] do
                # No changes detected, just report that
                log(
                  @log_level_essential,
                  "No changes needed - app.json matches version #{display_version} on the server.",
                  verbose
                )

                {false, latest_version["id"], false, display_version}
              else
                # There are changes, suggest creating a new version
                # We don't need to log anything here as the error will be shown in the run function
                {false, latest_version["id"], true, display_version}
              end
            end

          {:ok, response} ->
            Logger.error("Unexpected response format: #{inspect(response)}")
            {false, nil, false, nil}

          {:error, error} ->
            Logger.error("Error parsing response: #{inspect(error)}")
            {false, nil, false, nil}
        end

      {:ok, %Finch.Response{status: status, body: response_body}} ->
        Logger.error("Failed to get app versions. Status: #{status}")
        Logger.error("Response: #{response_body}")
        {false, nil, false, nil}

      {:error, error} ->
        Logger.error("Error getting app versions: #{inspect(error)}")
        {false, nil, false, nil}
    end
  end

  defp update_app_version_with_id(app_id, version_id, verbose, skip_draft_notice \\ false) do
    # Read the app.json file
    app_json_path = Path.join(File.cwd!(), "config/app.json")

    case File.read(app_json_path) do
      {:ok, content} ->
        case Jason.decode(content) do
          {:ok, app_json} ->
            # Transform the app_json to match the API's expected format
            transformed_json = transform_app_json(app_json)
            log(@log_level_debug, "Transformed JSON: #{Jason.encode!(transformed_json)}", verbose)
            app_version = transformed_json["app_version"]

            # First, get the current version to check for changes
            get_request =
              Finch.build(
                :get,
                "#{app_registry_url()}/#{app_id}/versions/#{version_id}",
                [
                  {"Authorization", "Bearer #{auth_token()}"},
                  {"Content-Type", "application/json"},
                  {"User-Agent", "phoenix_starter_kit/1.0.0"}
                ]
              )

            case Finch.request(get_request, SyncAppFinch) do
              {:ok, %Finch.Response{status: 200, body: response_body}} ->
                case Jason.decode(response_body) do
                  {:ok, %{"data" => current_version}} ->
                    # Compare with the current version
                    changes = detect_changes(app_version, current_version)

                    if changes == [] do
                      # No changes detected, skip the update
                      display_version = current_version["display_version"] || "0.0.0"

                      log(
                        @log_level_essential,
                        "No changes needed - app.json matches version #{display_version} on the server.",
                        verbose
                      )

                      # Check if the version is in draft status and inform the user
                      if current_version["status"] == "draft" && !skip_draft_notice do
                        log(
                          @log_level_essential,
                          "\nNOTE: This version is in DRAFT status and is not yet published.",
                          verbose
                        )

                        log(
                          @log_level_essential,
                          "To publish this version, run: mix sync_app_changes --publish",
                          verbose
                        )
                      end

                      # Return true to indicate success without making an update
                      true
                    else
                      # Changes detected, proceed with the update
                      update_version(
                        app_id,
                        version_id,
                        transformed_json,
                        verbose,
                        skip_draft_notice
                      )
                    end

                  _ ->
                    # Error parsing response, proceed with the update
                    update_version(
                      app_id,
                      version_id,
                      transformed_json,
                      verbose,
                      skip_draft_notice
                    )
                end

              _ ->
                # Error getting current version, proceed with the update
                update_version(app_id, version_id, transformed_json, verbose, skip_draft_notice)
            end

          {:error, error} ->
            Logger.error("Error parsing config/app.json: #{inspect(error)}")
            false
        end

      {:error, error} ->
        Logger.error("Error reading config/app.json: #{inspect(error)}")
        false
    end
  end

  defp update_version(app_id, version_id, transformed_json, verbose, skip_draft_notice) do
    log(@log_level_info, "Updating app version #{version_id} for app #{app_id}...", verbose)

    request =
      Finch.build(
        :put,
        "#{app_registry_url()}/#{app_id}/versions/#{version_id}",
        [
          {"Authorization", "Bearer #{auth_token()}"},
          {"Content-Type", "application/json"},
          {"User-Agent", "phoenix_starter_kit/1.0.0"}
        ],
        Jason.encode!(transformed_json)
      )

    case Finch.request(request, SyncAppFinch) do
      {:ok, %Finch.Response{status: status, body: response_body}} when status in 200..299 ->
        log(@log_level_info, "Successfully updated app version.", verbose)
        log(@log_level_debug, "Response: #{response_body}", verbose)

        # Parse the response to get the app ID and shared secret
        case Jason.decode(response_body) do
          {:ok, %{"data" => updated_version}} ->
            # Show a diff of what changed
            display_version = updated_version["display_version"] || "0.0.0"
            log(@log_level_essential, "Successfully updated version #{display_version}.", verbose)

            # Extract the important fields from the transformed JSON
            app_version = transformed_json["app_version"]

            # Compare and show differences for important fields
            changes = detect_changes(app_version, updated_version)

            # Log the changes only if there are any
            if changes != [] do
              Enum.each(changes, fn change -> log(@log_level_essential, change, verbose) end)
            end

            # Check if the version is in draft status and inform the user
            if updated_version["status"] == "draft" && !skip_draft_notice do
              log(
                @log_level_essential,
                "\nNOTE: This version is in DRAFT status and is not yet published.",
                verbose
              )

              log(
                @log_level_essential,
                "To publish this version, run: mix sync_app_changes --publish",
                verbose
              )
            end

            # Only update .env file if it's a new app (first time)
            if !get_app_id_from_env(verbose) && Map.has_key?(updated_version, "shared_secret_key") do
              # Get the app_url from the updated version
              app_url = Map.get(updated_version, "app_url")
              update_env_file(app_id, updated_version["shared_secret_key"], verbose, app_url)
            end

            true

          _ ->
            log(
              @log_level_essential,
              "App version updated successfully, but couldn't extract version details from response.",
              verbose
            )

            true
        end

      {:ok, %Finch.Response{status: status, body: response_body}} ->
        Logger.error("Failed to update app version. Status: #{status}")
        Logger.error("Response: #{response_body}")
        false

      {:error, error} ->
        Logger.error("Error updating app version: #{inspect(error)}")
        false
    end
  end

  defp create_app_version(app_id, display_version, verbose) do
    log(
      @log_level_essential,
      "Creating a new app version with display version: #{display_version}",
      verbose
    )

    # Prepare request body
    body =
      Jason.encode!(%{
        app_version: %{
          display_version: display_version
        }
      })

    # Make the request
    request =
      Finch.build(
        :post,
        "#{app_registry_url()}/#{app_id}/versions",
        [
          {"Authorization", "Bearer #{auth_token()}"},
          {"Content-Type", "application/json"},
          {"User-Agent", "phoenix_starter_kit/1.0.0"}
        ],
        body
      )

    case Finch.request(request, SyncAppFinch) do
      {:ok, %Finch.Response{status: status, body: response_body}} when status in 200..299 ->
        log(@log_level_essential, "Successfully created new app version.", verbose)
        log(@log_level_debug, "Response: #{response_body}", verbose)

        # Parse the response to get the version ID
        case Jason.decode(response_body) do
          {:ok, %{"data" => %{"id" => version_id}}} ->
            log(@log_level_essential, "New App Version ID: #{version_id}", verbose)

            # Now update the new version with the app.json content
            log(@log_level_essential, "Applying app.json content to the new version...", verbose)

            # Pass a flag to indicate this is a new version, so we don't show duplicate draft notifications
            updated = update_app_version_with_id(app_id, version_id, verbose, true)

            # Show a single, clear notification about the draft status
            log(
              @log_level_essential,
              "\nNOTE: Version #{display_version} created successfully and is in DRAFT status.",
              verbose
            )

            log(
              @log_level_essential,
              "To publish this version, run: mix sync_app_changes --publish",
              verbose
            )

            {updated, version_id}

          _ ->
            Logger.error(
              "App version created successfully, but couldn't extract version ID from response."
            )

            log(@log_level_debug, "Response: #{response_body}", verbose)
            {false, nil}
        end

      {:ok, %Finch.Response{status: 422, body: response_body}} ->
        Logger.error("Failed to create app version. Status: 422")
        Logger.error("Response: #{response_body}")

        if String.contains?(response_body, "There can be only one draft app version per app") do
          Logger.error("There is already a draft version for this app.")

          Logger.error(
            "You need to publish the existing draft version before creating a new one."
          )

          Logger.error("Run the following command to get information about the app versions:")
          Logger.error("  mix sync_app_changes --info")
          Logger.error("")
          Logger.error("Then run the following command to publish the draft version:")
          Logger.error("  mix sync_app_changes --publish")
        end

        {false, nil}

      {:ok, %Finch.Response{status: status, body: response_body}} ->
        Logger.error("Failed to create app version. Status: #{status}")
        Logger.error("Response: #{response_body}")
        {false, nil}

      {:error, error} ->
        Logger.error("Error creating app version: #{inspect(error)}")
        {false, nil}
    end
  end

  defp detect_changes(app_version, updated_version) do
    # Start with an empty list of changes
    name_changes =
      if Map.has_key?(app_version, "name") && Map.has_key?(updated_version, "name") &&
           app_version["name"] != updated_version["name"] do
        ["  Name: #{app_version["name"]} -> #{updated_version["name"]}"]
      else
        []
      end

    description_changes =
      if Map.has_key?(app_version, "description") && Map.has_key?(updated_version, "description") &&
           app_version["description"] != updated_version["description"] do
        ["  Description: #{app_version["description"]} -> #{updated_version["description"]}"]
      else
        []
      end

    base_url_changes =
      if Map.has_key?(app_version, "base_url") && Map.has_key?(updated_version, "base_url") &&
           app_version["base_url"] != updated_version["base_url"] do
        ["  Base URL: #{app_version["base_url"]} -> #{updated_version["base_url"]}"]
      else
        []
      end

    # Combine all changes
    all_changes = name_changes ++ description_changes ++ base_url_changes

    # Check for configured extensions changes
    if Map.has_key?(app_version, "configured_extendables") && all_changes == [] do
      # Get the extendables from the updated version
      updated_extendables =
        if Map.has_key?(updated_version, "extendables") do
          updated_version["extendables"]
        else
          []
        end

      # Compare the extendables
      if has_extendable_changes?(app_version["configured_extendables"], updated_extendables) do
        ["  Extensions configuration updated"]
      else
        all_changes
      end
    else
      all_changes
    end
  end

  defp has_extendable_changes?(configured_extendables, updated_extendables) do
    # If the lengths are different, there are changes
    if length(configured_extendables) != length(updated_extendables) do
      true
    else
      # Convert the configured extendables to a format that matches the updated extendables
      configured_slugs =
        configured_extendables
        |> Enum.map(fn extendable ->
          slug = extendable["extendable_slug"]
          config = extendable["configuration"]
          {slug, config}
        end)
        |> Enum.into(%{})

      # Convert the updated extendables to a format that matches the configured extendables
      updated_slugs =
        updated_extendables
        |> Enum.map(fn extendable ->
          slug = extendable["slug"]

          # Extract the configuration without the __type__ field
          config =
            extendable["configuration"]
            |> Map.drop(["__type__"])
            # Ignore timeout field as it's added by the API
            |> Map.drop(["timeout"])

          {slug, config}
        end)
        |> Enum.into(%{})

      # Compare the slugs and configurations
      configured_slugs_set = MapSet.new(Map.keys(configured_slugs))
      updated_slugs_set = MapSet.new(Map.keys(updated_slugs))

      # If the sets of slugs are different, there are changes
      if !MapSet.equal?(configured_slugs_set, updated_slugs_set) do
        true
      else
        # Check if any of the configurations are different
        Enum.any?(Map.keys(configured_slugs), fn slug ->
          # Get the configurations
          configured_config = configured_slugs[slug]
          updated_config = updated_slugs[slug]

          # Compare the configurations
          configured_config != updated_config
        end)
      end
    end
  end

  defp read_app_json(verbose) do
    log(@log_level_info, "Reading app.json from config/app.json", verbose)
    app_json_path = Path.join(File.cwd!(), "config/app.json")

    case File.read(app_json_path) do
      {:ok, content} ->
        case Jason.decode(content) do
          {:ok, decoded_json} ->
            decoded_json

          {:error, error} ->
            Mix.raise("Error parsing config/app.json: #{inspect(error)}")
        end

      {:error, error} ->
        Mix.raise("Error reading config/app.json: #{inspect(error)}")
    end
  end

  defp get_app_id_from_env(verbose) do
    # Load environment variables from .env file
    load_env_vars()

    # Check for app ID in environment variables
    app_id = System.get_env("PEEK_APP_ID")

    if app_id && app_id != "" do
      log(@log_level_info, "Using app ID from environment: #{app_id}", verbose)
      app_id
    else
      log(@log_level_info, "No app ID found in environment", verbose)
      nil
    end
  end

  defp get_app_name(verbose) do
    log(@log_level_info, "Reading app name from config/app.json", verbose)
    app_json_path = Path.join(File.cwd!(), "config/app.json")

    case File.read(app_json_path) do
      {:ok, content} ->
        case Jason.decode(content) do
          {:ok, %{"app_version" => %{"name" => app_name}}} ->
            log(@log_level_info, "Found app name: #{app_name}", verbose)
            app_name

          {:ok, _} ->
            Mix.raise(
              "Could not find app name in config/app.json. Expected 'app_version.name' field."
            )

          {:error, error} ->
            Mix.raise("Error parsing config/app.json: #{inspect(error)}")
        end

      {:error, error} ->
        Mix.raise("Error reading config/app.json: #{inspect(error)}")
    end
  end
end
