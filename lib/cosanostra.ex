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
    "wss://nos.lol"
  ]
  
  @doc """
  Connects to a Nostr relay with an optional timeout.
  
  ## Examples
  
      {:ok, client} = Cosanostra.connect("wss://relay.damus.io")
      {:ok, client} = Cosanostra.connect("wss://relay.damus.io", 10000) # 10 second timeout
  """
  def connect(url, timeout \\ 5000) do
    # Create a task to connect with a timeout
    task = Task.async(fn -> 
      # Pass the timeout to Relay.connect
      Relay.connect(url, [connect_timeout: timeout]) 
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
  
  ## Examples
  
      {:ok, client} = Cosanostra.connect("wss://relay.damus.io")
      {:ok, profile} = Cosanostra.get_profile(client, "pubkey")
  """
  def get_profile(client, pubkey_input, timeout \\ 5000) do
    # Normalize the public key (handle both npub and hex formats)
    with {:ok, pubkey} <- Utils.normalize_pubkey(pubkey_input) do
      # Create a task to collect the profile
      task = Task.async(fn ->
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
    {:error, :not_found}
  end
  
  defp process_profile_events(events) do
    # Find the most recent metadata event
    metadata_events = 
      events
      |> Enum.filter(&Event.metadata?/1)
      |> Enum.sort_by(fn event -> event.created_at end, :desc)
    
    case metadata_events do
      [] ->
        {:error, :not_found}
        
      [latest | _] ->
        # Parse the profile metadata
        Event.parse_metadata(latest)
    end
  end
  
  @doc """
  Fetches a user profile from multiple relays.
  
  ## Examples
  
      {:ok, profile} = Cosanostra.get_profile_from_relays("pubkey")
      {:ok, profile} = Cosanostra.get_profile_from_relays("pubkey", ["wss://relay1.com", "wss://relay2.com"])
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
              {:error, :no_relays_connected}
            else
              # Try to get profile from each relay
              profile_tasks = 
                Enum.map(clients, fn client ->
                  Task.async(fn -> get_profile(client, pubkey, timeout) end)
                end)
              
              # Wait for first successful result or all to finish
              results = Task.yield_many(profile_tasks, timeout)
              
              # Process results
              Enum.reduce_while(results, {:error, :not_found}, fn
                {_task, {:ok, {:ok, profile}}}, _acc ->
                  # Return first successful profile
                  {:halt, {:ok, profile}}
                  
                _, acc ->
                  # Continue with current acc
                  {:cont, acc}
              end)
            end
          after
            # Ensure all relays are closed
            Enum.each(clients, &Relay.close/1)
          end
          
        result
        
      error -> error
    end
  end
end
