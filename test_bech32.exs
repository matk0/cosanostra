# Test script for verifying Bech32 npub/hex conversion

# Make sure dependencies are loaded
Mix.install([
  {:bech32, "~> 1.0"}
])

defmodule TestUtils do
  # Constants for Nostr bech32 encoding
  @npub_hrp "npub"
  @pubkey_type 0

  def npub_to_hex("npub" <> _ = npub) do
    with {:ok, {_hrp, data}} <- Bech32.decode(npub),
         decoded_bytes <- Bech32.convertbits(data, 5, 8, false) do
      
      # Skip the first byte (type - 0x00 for pubkey) if it exists
      bytes_to_encode = if byte_size(decoded_bytes) > 32, do: binary_part(decoded_bytes, 1, 32), else: decoded_bytes
      hex = Base.encode16(bytes_to_encode, case: :lower)
      
      {:ok, hex}
    else
      {:error, reason} when is_atom(reason) -> {:error, "Invalid npub: #{reason}"}
      {:error, reason} -> {:error, reason}
      _ -> {:error, "Invalid npub format"}
    end
  end

  def npub_to_hex(_), do: {:error, "Not an npub"}

  def hex_to_npub(hex) when byte_size(hex) == 64 do
    with {:ok, decoded} <- Base.decode16(hex, case: :mixed),
         # Add type byte and convert to 5-bit
         data_with_type = <<@pubkey_type>> <> decoded,
         five_bit <- Bech32.convertbits(data_with_type, 8, 5, true) do
      
      # Encode with Bech32
      encoded = Bech32.encode(@npub_hrp, five_bit)
      {:ok, encoded}
    else
      :error -> {:error, "Invalid hex encoding"}
      {:error, reason} when is_atom(reason) -> {:error, "Conversion error: #{reason}"}
      {:error, reason} -> {:error, reason}
      _ -> {:error, "Invalid hex format"}
    end
  end

  def hex_to_npub(_), do: {:error, "Invalid hex format: must be 64 characters"}
end

# Test cases
test_keys = [
  # Our test key 1
  %{
    npub: "npub1t2j78z4mkdlcnjrrgxdare8xp233mqh68sunjl3cvkrw89smsqssy5nryq",
    hex: "5aa5e38abbb37f89c863419bd1e4e60aa31d82fa3c39397e386586e3961b8021"
  },
  # Jack Dorsey
  %{
    npub: "npub1sg6plzptd64u62a878hep2kev88swjh3tw00gjsfl8f237lmu63q0uf63m",
    hex: "82341f882b6eabcd2ba7f1ef90aad961cf074af15b9ef44a09f9d2a8fbfbe6a2"
  },
  # Random key 1
  %{
    npub: "npub1drvpw5qz6a55lq7zvqt9w80pdwgte93g00vh3ak37njayme9lngqhu3x9c",
    hex: "a7ecf96b666e7c297808158b6e89b8c947ee9ea4b0cda776ed7d278dc238b252"
  },
  # Random key 2
  %{
    npub: "npub10elfcs4fr0l0r8af98jlmgdh9c8tcxjvz5fz5p0c67p9tpqg6vsqzgeu5v",
    hex: "7e7e9c42a91bfef19fa929e5fda1b72e0eafd1f441a4d7ebb70f4d8962ff2979"
  }
]

IO.puts("=== Testing Bech32 Conversion Implementation ===")

Enum.each(test_keys, fn %{npub: npub, hex: hex} ->
  IO.puts("\nTesting key pair:")
  IO.puts("npub: #{npub}")
  IO.puts("hex:  #{hex}")
  
  # Test npub to hex
  IO.puts("\n1. Testing npub to hex conversion:")
  case TestUtils.npub_to_hex(npub) do
    {:ok, converted_hex} ->
      IO.puts("Converted: #{converted_hex}")
      if converted_hex == hex do
        IO.puts("✅ MATCH")
      else
        IO.puts("❌ NO MATCH - expected: #{hex}")
      end
    
    {:error, reason} ->
      IO.puts("❌ Error converting npub to hex: #{reason}")
  end
  
  # Test hex to npub
  IO.puts("\n2. Testing hex to npub conversion:")
  case TestUtils.hex_to_npub(hex) do
    {:ok, converted_npub} ->
      IO.puts("Converted: #{converted_npub}")
      if converted_npub == npub do
        IO.puts("✅ MATCH")
      else
        IO.puts("❌ NO MATCH - expected: #{npub}")
      end
    
    {:error, reason} ->
      IO.puts("❌ Error converting hex to npub: #{reason}")
  end
  
  # Test round trip
  IO.puts("\n3. Testing round trip (npub -> hex -> npub):")
  with {:ok, converted_hex} <- TestUtils.npub_to_hex(npub),
       {:ok, round_trip_npub} <- TestUtils.hex_to_npub(converted_hex) do
    IO.puts("Original npub:  #{npub}")
    IO.puts("Round trip:     #{round_trip_npub}")
    if round_trip_npub == npub do
      IO.puts("✅ MATCH")
    else
      IO.puts("❌ NO MATCH")
    end
  else
    error -> IO.puts("❌ Error in round trip: #{inspect(error)}")
  end
  
  IO.puts("\n---------------------------------------------------")
end)

IO.puts("\n=== All Tests Completed ===")