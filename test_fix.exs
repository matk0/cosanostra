#!/usr/bin/env elixir
# Test script to verify the npub/hex conversion fix

Mix.install([
  {:websockex, "~> 0.4.3"},
  {:jason, "~> 1.4"}
])

# Force compilation of our project
Code.compile_file("lib/cosanostra/utils.ex")
Code.compile_file("lib/cosanostra/event.ex")
Code.compile_file("lib/cosanostra/relay.ex")
Code.compile_file("lib/cosanostra.ex")

defmodule ConversionTester do
  def run do
    # The npub and hex values we're testing
    npub = "npub1t2j78z4mkdlcnjrrgxdare8xp233mqh68sunjl3cvkrw89smsqssy5nryq"
    hex = "5aa5e38abbb37f89c863419bd1e4e60aa31d82fa3c39397e386586e3961b8021"
    
    IO.puts("\n=== Testing Conversion Fix ===")
    
    # Test the npub to hex conversion
    IO.puts("\nTesting npub to hex conversion:")
    case Cosanostra.Utils.npub_to_hex(npub) do
      {:ok, converted_hex} ->
        IO.puts("Converted npub to hex: #{converted_hex}")
        IO.puts("Expected hex:          #{hex}")
        IO.puts("Match: #{converted_hex == hex}")
        
      error ->
        IO.puts("Error converting npub to hex: #{inspect(error)}")
    end
    
    # Test the hex to npub conversion
    IO.puts("\nTesting hex to npub conversion:")
    case Cosanostra.Utils.hex_to_npub(hex) do
      {:ok, converted_npub} ->
        IO.puts("Converted hex to npub: #{converted_npub}")
        IO.puts("Expected npub:         #{npub}")
        IO.puts("Match: #{converted_npub == npub}")
        
      error ->
        IO.puts("Error converting hex to npub: #{inspect(error)}")
    end
    
    # Test normalizing the npub
    IO.puts("\nTesting normalize with npub:")
    case Cosanostra.Utils.normalize_pubkey(npub) do
      {:ok, normalized} ->
        IO.puts("Normalized npub: #{normalized}")
        IO.puts("Expected hex:    #{hex}")
        IO.puts("Match: #{normalized == hex}")
        
      error ->
        IO.puts("Error normalizing npub: #{inspect(error)}")
    end
    
    # Test normalizing the hex
    IO.puts("\nTesting normalize with hex:")
    case Cosanostra.Utils.normalize_pubkey(hex) do
      {:ok, normalized} ->
        IO.puts("Normalized hex: #{normalized}")
        IO.puts("Expected hex:   #{hex}")
        IO.puts("Match: #{normalized == hex}")
        
      error ->
        IO.puts("Error normalizing hex: #{inspect(error)}")
    end
    
    IO.puts("\n=== Testing Completed ===")
  end
end

# Run the test
ConversionTester.run()