#!/usr/bin/env elixir
# Simple script to test the profile fetching functionality

Mix.install([
  {:websockex, "~> 0.4.3"},
  {:jason, "~> 1.4"}
])

# Force compilation of our project
Code.compile_file("lib/cosanostra/utils.ex")
Code.compile_file("lib/cosanostra/event.ex")
Code.compile_file("lib/cosanostra/relay.ex")
Code.compile_file("lib/cosanostra.ex")

defmodule ProfileTester do
  def run do
    # Matej's public key
    pubkey = "5aa5e38abbb37f89c863419bd1e4e60aa31d82fa3c39397e386586e3961b8021"
    
    IO.puts("\n=== Testing Profile Fetching ===")
    IO.puts("Fetching profile for: #{pubkey}")
    
    # Set log level to debug to see detailed logs
    Logger.configure(level: :debug)
    
    # Try to get the profile from multiple relays
    relays = [
      "wss://relay.damus.io",
      "wss://relay.nostr.band",
      "wss://nos.lol",
      "wss://nostr.fmt.wiz.biz",
      "wss://relay.nostr.info",
      "wss://purplepag.es"
    ]
    
    case Cosanostra.get_profile_from_relays(pubkey, relays) do
      {:ok, profile} ->
        IO.puts("\n=== Profile Retrieved ===")
        IO.puts("Name: #{profile["name"] || "N/A"}")
        IO.puts("Display Name: #{profile["display_name"] || profile["displayName"] || "N/A"}")
        IO.puts("About: #{profile["about"] || "N/A"}")
        IO.puts("Picture: #{profile["picture"] || "N/A"}")
        IO.puts("Website: #{profile["website"] || "N/A"}")
        IO.puts("Created at: #{format_timestamp(profile["created_at"])}")
        
      {:error, reason} ->
        IO.puts("\n=== Error ===")
        IO.puts("Failed to get profile: #{inspect(reason)}")
    end
  end
  
  defp format_timestamp(nil), do: "unknown"
  defp format_timestamp(timestamp) do
    {:ok, datetime} = DateTime.from_unix(timestamp)
    "#{datetime} (#{timestamp})"
  end
end

# Run the test
ProfileTester.run()
