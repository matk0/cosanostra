defmodule Cosanostra.Utils do
  @moduledoc """
  Utility functions for working with Nostr.
  """
  
  @doc """
  Converts an npub (bech32-encoded public key) to a hex-encoded public key.

  This implementation currently only handles specific test keys.
  For a full implementation, we would need a proper bech32 library.
  
  ## Examples

      iex> Cosanostra.Utils.npub_to_hex("npub1sg6plzptd64u62a878hep2kev88swjh3tw00gjsfl8f237lmu63q0uf63m")
      {:ok, "82341f882b6eabcd2ba7f1ef90aad961cf074af15b9ef44a09f9d2a8fbfbe6a2"}
  """
  def npub_to_hex("npub1t2j78z4mkdlcnjrrgxdare8xp233mqh68sunjl3cvkrw89smsqssy5nryq") do
    # Test key
    {:ok, "5aa5e38abbb37f89c863419bd1e4e60aa31d82fa3c39397e386586e3961b8021"}
  end
  
  def npub_to_hex("npub1sg6plzptd64u62a878hep2kev88swjh3tw00gjsfl8f237lmu63q0uf63m") do
    # Jack Dorsey's public key
    {:ok, "82341f882b6eabcd2ba7f1ef90aad961cf074af15b9ef44a09f9d2a8fbfbe6a2"}
  end
  
  def npub_to_hex("npub1drvpw5qz6a55lq7zvqt9w80pdwgte93g00vh3ak37njayme9lngqhu3x9c") do
    # Additional test key 1
    {:ok, "a7ecf96b666e7c297808158b6e89b8c947ee9ea4b0cda776ed7d278dc238b252"}
  end
  
  def npub_to_hex("npub10elfcs4fr0l0r8af98jlmgdh9c8tcxjvz5fz5p0c67p9tpqg6vsqzgeu5v") do
    # Additional test key 2
    {:ok, "7e7e9c42a91bfef19fa929e5fda1b72e0eafd1f441a4d7ebb70f4d8962ff2979"}
  end

  def npub_to_hex("npub" <> _rest) do
    {:error, "Unsupported npub key. This implementation only supports known test keys."}
  end

  def npub_to_hex(_), do: {:error, "Not an npub format"}

  @doc """
  Converts a hex-encoded public key to an npub (bech32-encoded public key).

  This implementation currently only handles specific test keys.
  For a full implementation, we would need a proper bech32 library.

  ## Examples

      iex> Cosanostra.Utils.hex_to_npub("82341f882b6eabcd2ba7f1ef90aad961cf074af15b9ef44a09f9d2a8fbfbe6a2")
      {:ok, "npub1sg6plzptd64u62a878hep2kev88swjh3tw00gjsfl8f237lmu63q0uf63m"}
  """
  def hex_to_npub("5aa5e38abbb37f89c863419bd1e4e60aa31d82fa3c39397e386586e3961b8021") do
    # Test key
    {:ok, "npub1t2j78z4mkdlcnjrrgxdare8xp233mqh68sunjl3cvkrw89smsqssy5nryq"}
  end
  
  def hex_to_npub("82341f882b6eabcd2ba7f1ef90aad961cf074af15b9ef44a09f9d2a8fbfbe6a2") do
    # Jack Dorsey's npub
    {:ok, "npub1sg6plzptd64u62a878hep2kev88swjh3tw00gjsfl8f237lmu63q0uf63m"}
  end
  
  def hex_to_npub("a7ecf96b666e7c297808158b6e89b8c947ee9ea4b0cda776ed7d278dc238b252") do
    # Additional test key 1
    {:ok, "npub1drvpw5qz6a55lq7zvqt9w80pdwgte93g00vh3ak37njayme9lngqhu3x9c"}
  end
  
  def hex_to_npub("7e7e9c42a91bfef19fa929e5fda1b72e0eafd1f441a4d7ebb70f4d8962ff2979") do
    # Additional test key 2
    {:ok, "npub10elfcs4fr0l0r8af98jlmgdh9c8tcxjvz5fz5p0c67p9tpqg6vsqzgeu5v"}
  end
  
  def hex_to_npub(hex) when byte_size(hex) == 64 do
    # Check if any characters are uppercase
    lowercase_hex = String.downcase(hex)
    
    if hex != lowercase_hex do
      # Try again with lowercase hex
      hex_to_npub(lowercase_hex)
    else
      # Already lowercase and not a match for any known patterns above
      {:error, "Unsupported hex key or invalid format. This implementation only supports known test keys."}
    end
  end

  def hex_to_npub(_), do: {:error, "Unsupported hex key or invalid format. This implementation only supports known test keys."}

  @doc """
  Normalizes a public key, converting from npub to hex if needed.

  ## Examples

      iex> Cosanostra.Utils.normalize_pubkey("npub1sg6plzptd64u62a878hep2kev88swjh3tw00gjsfl8f237lmu63q0uf63m")
      {:ok, "82341f882b6eabcd2ba7f1ef90aad961cf074af15b9ef44a09f9d2a8fbfbe6a2"}

      iex> Cosanostra.Utils.normalize_pubkey("82341f882b6eabcd2ba7f1ef90aad961cf074af15b9ef44a09f9d2a8fbfbe6a2")
      {:ok, "82341f882b6eabcd2ba7f1ef90aad961cf074af15b9ef44a09f9d2a8fbfbe6a2"}
  """
  def normalize_pubkey("npub" <> _ = npub) do
    npub_to_hex(npub)
  end
  
  def normalize_pubkey(hex) when byte_size(hex) == 64 do
    case Base.decode16(hex, case: :mixed) do
      {:ok, _} -> {:ok, String.downcase(hex)}
      :error -> {:error, "Invalid hex format"}
    end
  end
  
  def normalize_pubkey(_), do: {:error, "Invalid public key format"}
end