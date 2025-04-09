defmodule Cosanostra do
  @moduledoc """
  Cosanostra is an Elixir client for the Nostr protocol.

  This library allows you to connect to Nostr relays, subscribe to events,
  and fetch profile information from the Nostr network.
  """
  alias Cosanostra.Relay
  alias Cosanostra.Event
  alias Cosanostra.Utils
  require Logger

  @default_relays [
    "wss://relay.damus.io",
    "wss://relay.nostr.band",
    "wss://nos.lol",
    "wss://purplepag.es/",
    "wss://pyramid.fiatjaf.com/",
    "wss://relay.primal.net/"
  ]

  @doc """
  Connects to a Nostr relay with an optional timeout.

  ## Examples

      {:ok, client} = Cosanostra.connect("wss://relay.damus.io")
      {:ok, client} = Cosanostra.connect("wss://relay.damus.io", 10000) # 10 second timeout
  """
  def connect(url, timeout \\ 5000) do
    # Create a task to connect with a timeout
    task =
      Task.async(fn ->
        # Pass the timeout to Relay.connect
        Relay.connect(url, connect_timeout: timeout)
      end)

    # Wait for the connection with the specified timeout
    case Task.yield(task, timeout + 1000) || Task.shutdown(task) do
      {:ok, result} ->
        result

      nil ->
        Logger.warning("Connection to #{url} timed out after #{timeout}ms")
        {:error, :timeout}
    end
  end

  @doc """
  Fetches a user profile from a relay.
  
  Accepts either hex-encoded or npub-formatted public keys. The key
  will be automatically normalized to hex format before querying the relay.

  ## Examples

      {:ok, client} = Cosanostra.connect("wss://relay.damus.io")
      
      # With hex-encoded pubkey
      {:ok, profile} = Cosanostra.get_profile(client, "82341f882b6eabcd2ba7f1ef90aad961cf074af15b9ef44a09f9d2a8fbfbe6a2")
      
      # With npub format
      {:ok, profile} = Cosanostra.get_profile(client, "npub1sg6plzptd64u62a878hep2kev88swjh3tw00gjsfl8f237lmu63q0uf63m")
  """
  def get_profile(client, pubkey_input, timeout \\ 5000) do
    # Normalize the public key (handle both npub and hex formats)
    with {:ok, pubkey} <- Utils.normalize_pubkey(pubkey_input) do
      # Create a task to collect the profile
      task =
        Task.async(fn ->
          # Create a short subscription ID
          subscription_id = "sub_#{System.unique_integer([:positive])}"

          # Subscribe to this user's metadata events (kind 0)
          filter = %{kinds: [0], authors: [pubkey], limit: 1}
          Relay.subscribe(client, filter, subscription_id, self())

          # Process and collect events
          result = collect_profile_events(subscription_id, timeout)

          # Unsubscribe
          Relay.unsubscribe(client, subscription_id)

          result
        end)

      # Wait for the task to complete or timeout
      case Task.yield(task, timeout + 1000) || Task.shutdown(task) do
        {:ok, result} -> result
        nil -> {:error, :timeout}
      end
    else
      {:error, reason} -> {:error, reason}
    end
  end

  # Helper function to collect profile events
  defp collect_profile_events(subscription_id, timeout) do
    # Set a deadline
    deadline = System.monotonic_time(:millisecond) + timeout
    collect_events([], subscription_id, deadline)
  end

  defp collect_events(events, subscription_id, deadline) do
    # Check remaining time
    remaining = deadline - System.monotonic_time(:millisecond)

    if remaining <= 0 do
      # We've hit the timeout
      if events == [] do
        {:error, :timeout}
      else
        # Process the collected events
        process_profile_events(events)
      end
    else
      # Wait for events or EOSE
      receive do
        {:event, ^subscription_id, event} ->
          # Add the event to our collection
          collect_events([event | events], subscription_id, deadline)

        {:eose, ^subscription_id} ->
          # End of stored events, process what we have
          process_profile_events(events)
      after
        remaining ->
          # We've hit the timeout
          if events == [] do
            {:error, :timeout}
          else
            # Process the collected events
            process_profile_events(events)
          end
      end
    end
  end

  defp process_profile_events([]) do
    Logger.info("No events found to process")
    {:error, :not_found}
  end

  defp process_profile_events(events) do
    Logger.info("Processing #{length(events)} events")

    # Log all events for debugging
    Enum.each(events, fn event ->
      Logger.info(
        "Event ID: #{String.slice(event.id, 0, 10)}..., kind: #{event.kind}, created_at: #{event.created_at || "nil"}"
      )

      Logger.debug("Event content: #{String.slice(event.content || "", 0, 100)}...")
    end)

    # Find the most recent metadata event
    metadata_events =
      events
      |> Enum.filter(&Event.metadata?/1)
      |> Enum.sort_by(fn event -> event.created_at end, :desc)

    Logger.info("Found #{length(metadata_events)} metadata events")

    case metadata_events do
      [] ->
        Logger.info("No metadata events found")
        {:error, :not_found}

      [latest | _] ->
        # Log the latest event
        Logger.info(
          "Latest event: ID #{String.slice(latest.id, 0, 10)}..., created_at: #{latest.created_at || "nil"}"
        )

        Logger.info("Raw content: #{latest.content}")

        # Parse the profile metadata
        result = Event.parse_metadata(latest)

        # Log the parsing result
        case result do
          {:ok, profile} ->
            Logger.info("Successfully parsed profile metadata")

            # Log the created_at field specifically
            if profile["created_at"] do
              Logger.info("Profile created_at: #{profile["created_at"]}")
            else
              Logger.info("Profile has no created_at field")
            end

          error ->
            Logger.info("Error parsing profile: #{inspect(error)}")
        end

        result
    end
  end

  @doc """
  Fetches a user profile from multiple relays.
  
  Accepts either hex-encoded or npub-formatted public keys. The key
  will be automatically normalized to hex format before querying the relays.
  
  Returns the most recent profile based on the created_at timestamp.

  ## Examples

      # With hex-encoded pubkey
      {:ok, profile} = Cosanostra.get_profile_from_relays("82341f882b6eabcd2ba7f1ef90aad961cf074af15b9ef44a09f9d2a8fbfbe6a2")
      
      # With npub format
      {:ok, profile} = Cosanostra.get_profile_from_relays("npub1sg6plzptd64u62a878hep2kev88swjh3tw00gjsfl8f237lmu63q0uf63m")
      
      # With custom relays
      {:ok, profile} = Cosanostra.get_profile_from_relays("npub1sg6plzptd64u62a878hep2kev88swjh3tw00gjsfl8f237lmu63q0uf63m", ["wss://relay1.com", "wss://relay2.com"])
  """
  def get_profile_from_relays(pubkey_input, relays \\ @default_relays, timeout \\ 5000) do
    # Normalize the public key (handle both npub and hex formats)
    case Utils.normalize_pubkey(pubkey_input) do
      {:ok, pubkey} ->
        # Connect to multiple relays in parallel
        relay_tasks =
          Enum.map(relays, fn url ->
            Task.async(fn ->
              case connect(url) do
                {:ok, client} -> {url, client, :ok}
                error -> {url, nil, error}
              end
            end)
          end)

        # Wait for connections
        relay_results = Task.await_many(relay_tasks, timeout)

        # Filter successful connections
        clients =
          relay_results
          |> Enum.filter(fn
            {_url, client, :ok} when is_pid(client) -> true
            _ -> false
          end)
          |> Enum.map(fn {_url, client, :ok} -> client end)

        result =
          try do
            # If no relays connected, return error
            if clients == [] do
              Logger.warning("No relays connected, can't fetch profile")
              {:error, :no_relays_connected}
            else
              # Log how many relays we connected to
              Logger.info("Connected to #{length(clients)} relays for profile lookup")
              # Try to get profile from each relay
              profile_tasks =
                Enum.map(clients, fn client ->
                  Task.async(fn -> get_profile(client, pubkey, timeout) end)
                end)

              # Wait for first successful result or all to finish
              results = Task.yield_many(profile_tasks, timeout)

              # Process results - collect all successful profiles
              profiles =
                Enum.reduce(results, [], fn
                  {_task, {:ok, {:ok, profile}}}, acc ->
                    # Add successful profile to accumulator with source information
                    profile_with_info = Map.put(profile, "__relay_info", "Found profile")
                    [profile_with_info | acc]

                  {_task, {:ok, {:error, :not_found}}}, acc ->
                    # Not found on this relay
                    acc

                  {_task, error}, acc ->
                    # Log error but skip it
                    Logger.debug("Error fetching profile: #{inspect(error)}")
                    acc
                end)

              # Debug logging of all profiles with detailed information
              debug_log_profiles(profiles, pubkey, true)

              case profiles do
                [] ->
                  # No profiles found
                  {:error, :not_found}

                profiles ->
                  # Find the most recent profile by created_at timestamp
                  latest_profile =
                    profiles
                    |> Enum.sort_by(
                      fn profile ->
                        # Get created_at from the profile map, default to 0 if not present
                        profile["created_at"] || 0
                      end,
                      :desc
                    )
                    |> List.first()

                  {:ok, latest_profile}
              end
            end
          after
            # Ensure all relays are closed
            Enum.each(clients, &Relay.close/1)
          end

        result

      error ->
        error
    end
  end

  # Helper function to log all retrieved profiles for debugging
  defp debug_log_profiles(profiles, pubkey, verbose \\ false) do
    if Enum.empty?(profiles) do
      Logger.info("No profiles found for pubkey: #{pubkey}")
    else
      sorted_profiles =
        profiles
        |> Enum.sort_by(fn profile -> profile["created_at"] || 0 end, :desc)

      Logger.info("Found #{length(profiles)} profiles for pubkey: #{pubkey}")

      # Log each profile with its timestamp
      Enum.with_index(sorted_profiles)
      |> Enum.each(fn {profile, index} ->
        created_at = profile["created_at"]

        formatted_time =
          if created_at != nil && created_at > 0 do
            {:ok, datetime} = DateTime.from_unix(created_at)
            DateTime.to_string(datetime)
          else
            "unknown time (nil or 0 value)"
          end

        name = profile["name"] || "unnamed"

        about =
          if Map.has_key?(profile, "about"),
            do: String.slice(profile["about"] || "", 0, 30),
            else: "no about"

        Logger.info("Profile #{index + 1}: #{name} (#{formatted_time}) - #{about}...")

        # Log full profile in verbose mode
        if verbose do
          Logger.info("Full profile #{index + 1} data:")

          profile
          |> Enum.sort_by(fn {k, _} -> k end)
          |> Enum.each(fn {key, value} ->
            Logger.info("  #{key}: #{inspect(value)}")
          end)
        end
      end)

      # Log which profile was selected
      latest = List.first(sorted_profiles)
      name = latest["name"] || "unnamed"
      created_at = latest["created_at"] || 0

      formatted_time =
        if created_at > 0 do
          {:ok, datetime} = DateTime.from_unix(created_at)
          DateTime.to_string(datetime)
        else
          "unknown time"
        end

      Logger.info("Selected latest profile: #{name} (#{formatted_time})")
    end
  end
end
