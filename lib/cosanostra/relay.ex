defmodule Cosanostra.Relay do
  @moduledoc """
  Handles connections to Nostr relays.
  """
  use WebSockex
  require Logger

  defstruct [:url, :status, subscriptions: %{}]

  @doc """
  Connects to a Nostr relay.

  ## Examples

      {:ok, client} = Cosanostra.Relay.connect("wss://relay.damus.io")
  """
  def connect(url) do
    WebSockex.start_link(url, __MODULE__, %{
      url: url,
      subscriptions: %{},
      status: :connecting
    })
  end

  @doc """
  Subscribes to events matching the given filter.

  ## Examples

      subscription_id = Cosanostra.Relay.subscribe(client, %{kinds: [0], authors: ["pubkey"]})
  """
  def subscribe(client, filter, subscription_id \\ nil, subscriber \\ nil) do
    subscription_id = subscription_id || generate_subscription_id()
    
    # Register the subscriber if provided
    if subscriber do
      :ok = register_subscriber(client, subscription_id, subscriber)
    end
    
    req = ["REQ", subscription_id, filter]
    WebSockex.send_frame(client, {:text, Jason.encode!(req)})
    
    subscription_id
  end
  
  @doc """
  Registers a process to receive events for a subscription.
  
  ## Examples
  
      Cosanostra.Relay.register_subscriber(client, subscription_id, self())
  """
  def register_subscriber(client, subscription_id, subscriber) do
    WebSockex.cast(client, {:register_subscriber, subscription_id, subscriber})
  end

  @doc """
  Unsubscribes from a subscription.

  ## Examples

      Cosanostra.Relay.unsubscribe(client, subscription_id)
  """
  def unsubscribe(client, subscription_id) do
    req = ["CLOSE", subscription_id]
    WebSockex.send_frame(client, {:text, Jason.encode!(req)})
  end

  @doc """
  Closes the connection to the relay.

  ## Examples

      Cosanostra.Relay.close(client)
  """
  def close(client) do
    Process.exit(client, :normal)
  end

  # WebSockex callbacks

  def handle_connect(_conn, state) do
    Logger.info("Connected to Nostr relay: #{state.url}")
    {:ok, %{state | status: :connected}}
  end

  def handle_frame({:text, msg}, state) do
    case Jason.decode(msg) do
      {:ok, ["EVENT", subscription_id, event_data]} ->
        Logger.debug("Received event for subscription #{subscription_id}")
        
        # Convert the event data to our Event struct
        event = 
          case Cosanostra.Event.from_map(event_data) do
            %Cosanostra.Event{} = event -> event
            {:error, reason} -> 
              Logger.warning("Error parsing event: #{inspect(reason)}")
              nil
          end
        
        # Forward the event to subscribers if valid
        if event do
          forward_to_subscribers(state, subscription_id, event)
        end
        
        {:ok, state}

      {:ok, ["EOSE", subscription_id]} ->
        Logger.debug("End of stored events for subscription #{subscription_id}")
        
        # Forward EOSE to subscribers
        forward_eose_to_subscribers(state, subscription_id)
        
        {:ok, state}
        
      {:ok, ["NOTICE", message]} ->
        Logger.info("Notice from relay: #{message}")
        {:ok, state}
        
      {:ok, other} ->
        Logger.debug("Received unknown message: #{inspect(other)}")
        {:ok, state}
        
      {:error, error} ->
        Logger.error("Error decoding message: #{inspect(error)}")
        {:ok, state}
    end
  end
  
  # Handle the register_subscriber message
  def handle_cast({:register_subscriber, subscription_id, subscriber}, state) do
    # Add the subscriber to the subscription
    new_subscriptions = Map.update(
      state.subscriptions, 
      subscription_id, 
      [subscriber], 
      fn subscribers -> [subscriber | subscribers] end
    )
    
    {:ok, %{state | subscriptions: new_subscriptions}}
  end
  
  # Handle other casts
  def handle_cast(msg, state) do
    Logger.debug("Unhandled cast: #{inspect(msg)}")
    {:ok, state}
  end

  def handle_disconnect(%{reason: reason}, state) do
    Logger.warning("Disconnected from Nostr relay: #{inspect(reason)}")
    {:reconnect, %{state | status: :reconnecting}}
  end

  def terminate(reason, state) do
    Logger.info("Terminating connection to #{state.url}: #{inspect(reason)}")
    :ok
  end

  # Helper functions
  
  defp generate_subscription_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end
  
  defp forward_to_subscribers(state, subscription_id, event) do
    case Map.get(state.subscriptions, subscription_id) do
      nil -> 
        :ok
      
      subscribers ->
        # Send the event to all subscribers
        for subscriber <- subscribers do
          send(subscriber, {:event, subscription_id, event})
        end
        :ok
    end
  end
  
  defp forward_eose_to_subscribers(state, subscription_id) do
    case Map.get(state.subscriptions, subscription_id) do
      nil -> 
        :ok
      
      subscribers ->
        # Send EOSE to all subscribers
        for subscriber <- subscribers do
          send(subscriber, {:eose, subscription_id})
        end
        :ok
    end
  end
end