#!/usr/bin/env elixir
# Test script to verify profile fetching with both npub and hex

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
    # Test keys to try
    test_keys = [
      # Jack Dorsey
      %{
        name: "Jack Dorsey",
        npub: "npub1sg6plzptd64u62a878hep2kev88swjh3tw00gjsfl8f237lmu63q0uf63m",
        hex: "82341f882b6eabcd2ba7f1ef90aad961cf074af15b9ef44a09f9d2a8fbfbe6a2"
      },
      # Test key 1 
      %{
        name: "Test key 1",
        npub: "npub1t2j78z4mkdlcnjrrgxdare8xp233mqh68sunjl3cvkrw89smsqssy5nryq",
        hex: "5aa5e38abbb37f89c863419bd1e4e60aa31d82fa3c39397e386586e3961b8021"
      },
      # Test key 2
      %{
        name: "Test key 2",
        npub: "npub1drvpw5qz6a55lq7zvqt9w80pdwgte93g00vh3ak37njayme9lngqhu3x9c",
        hex: "a7ecf96b666e7c297808158b6e89b8c947ee9ea4b0cda776ed7d278dc238b252"
      },
      # Test key 3
      %{
        name: "Test key 3",
        npub: "npub10elfcs4fr0l0r8af98jlmgdh9c8tcxjvz5fz5p0c67p9tpqg6vsqzgeu5v",
        hex: "7e7e9c42a91bfef19fa929e5fda1b72e0eafd1f441a4d7ebb70f4d8962ff2979"
      }
    ]
    
    # Set log level
    Logger.configure(level: :info)
    
    IO.puts("\n=== Testing Profile Fetching ===")
    
    Enum.each(test_keys, fn %{name: name, npub: npub, hex: hex} ->
      IO.puts("\n----- Testing #{name} profile -----")
      
      # Test fetching with hex
      IO.puts("\nFetching profile with hex key:")
      fetch_profile(hex)
      
      # Test fetching with npub
      IO.puts("\nFetching profile with npub key:")
      fetch_profile(npub)
      
      IO.puts("\n----------------------------")
    end)
    
    IO.puts("\n=== Testing Completed ===")
  end
  
  defp fetch_profile(key) do
    # Try to get the profile from multiple relays
    relays = [
      "wss://relay.damus.io",
      "wss://relay.nostr.band",
      "wss://nos.lol",
      "wss://purplepag.es/",
      "wss://pyramid.fiatjaf.com/",
      "wss://relay.primal.net/"
    ]
    
    IO.puts("Using key: #{key}")
    
    case Cosanostra.get_profile_from_relays(key, relays, 10000) do
      {:ok, profile} ->
        IO.puts("\n✅ Profile retrieved successfully!")
        IO.puts("Name: #{profile["name"] || "N/A"}")
        IO.puts("Display Name: #{profile["display_name"] || profile["displayName"] || "N/A"}")
        IO.puts("About: #{String.slice(profile["about"] || "", 0, 50)}...")
        if profile["picture"], do: IO.puts("Picture: #{profile["picture"]}")
        IO.puts("Created at: #{format_timestamp(profile["created_at"])}")
        IO.puts("Event ID: #{String.slice(profile["event_id"] || "", 0, 20)}...")
        
      {:error, reason} ->
        IO.puts("\n❌ Failed to get profile: #{inspect(reason)}")
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