# Test script for verifying our hardcoded npub/hex key conversion

# Load the Utils module directly
Code.require_file("lib/cosanostra/utils.ex")

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

IO.puts("\n=== Testing Pubkey Conversion ===")

Enum.each(test_keys, fn %{npub: npub, hex: hex} ->
  IO.puts("\nTesting key pair:")
  IO.puts("npub: #{npub}")
  IO.puts("hex:  #{hex}")
  
  # Test npub to hex
  IO.puts("\n1. Testing npub to hex conversion:")
  case Cosanostra.Utils.npub_to_hex(npub) do
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
  case Cosanostra.Utils.hex_to_npub(hex) do
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
  
  # Test normalize_pubkey
  IO.puts("\n3. Testing normalize_pubkey function:")
  
  # With npub
  case Cosanostra.Utils.normalize_pubkey(npub) do
    {:ok, normalized} ->
      IO.puts("Normalized npub: #{normalized}")
      if normalized == hex do
        IO.puts("✅ MATCH - npub normalized to hex correctly")
      else
        IO.puts("❌ NO MATCH - expected: #{hex}, got: #{normalized}")
      end
    
    error -> IO.puts("❌ Error normalizing npub: #{inspect(error)}")
  end
  
  # With hex
  case Cosanostra.Utils.normalize_pubkey(hex) do
    {:ok, normalized} ->
      IO.puts("Normalized hex: #{normalized}")
      if normalized == hex do
        IO.puts("✅ MATCH - hex normalized to hex correctly")
      else
        IO.puts("❌ NO MATCH - expected: #{hex}, got: #{normalized}")
      end
    
    error -> IO.puts("❌ Error normalizing hex: #{inspect(error)}")
  end
  
  IO.puts("\n---------------------------------------------------")
end)

# Test the normalize_pubkey function with uppercase hex
IO.puts("\n=== Testing uppercase hex normalization ===")
hex = "82341F882B6EABCD2BA7F1EF90AAD961CF074AF15B9EF44A09F9D2A8FBFBE6A2"
expected = "82341f882b6eabcd2ba7f1ef90aad961cf074af15b9ef44a09f9d2a8fbfbe6a2"

case Cosanostra.Utils.normalize_pubkey(hex) do
  {:ok, normalized} ->
    IO.puts("Normalized uppercase hex: #{normalized}")
    if normalized == expected do
      IO.puts("✅ MATCH - normalized to lowercase correctly")
    else
      IO.puts("❌ NO MATCH")
    end
  
  error -> IO.puts("❌ Error: #{inspect(error)}")
end

IO.puts("\n=== All Tests Completed ===")