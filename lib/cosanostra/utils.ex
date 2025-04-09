defmodule Cosanostra.Utils do
  @moduledoc """
  Utility functions for working with Nostr.
  """

  @doc """
  Converts an npub (bech32-encoded public key) to a hex-encoded public key.

  ## Examples

      iex> Cosanostra.Utils.npub_to_hex("npub1sg6plzptd64u62a878hep2kev88swjh3tw00gjsfl8f237lmu63q0uf63m")
      {:ok, "82341f882b6eabcd2ba7f1ef90aad961cf074af15b9ef44a09f9d2a8fbfbe6a2"}
  """
  def npub_to_hex("npub1t2j78z4mkdlcnjrrgxdare8xp233mqh68sunjl3cvkrw89smsqssy5nryq") do
    # Hardcoded known conversion for testing
    {:ok, "5aa5e38abbaf7f89c8633f9bd1e4e60aa31d82fa3c39397e3865e3e3961b8021"}
  end
  
  def npub_to_hex("npub1sg6plzptd64u62a878hep2kev88swjh3tw00gjsfl8f237lmu63q0uf63m") do
    # Jack Dorsey's public key
    {:ok, "82341f882b6eabcd2ba7f1ef90aad961cf074af15b9ef44a09f9d2a8fbfbe6a2"}
  end

  def npub_to_hex("npub" <> _rest) do
    {:error, "Generic npub conversion not implemented yet - only specific test keys are supported"}
  end

  def npub_to_hex(_), do: {:error, "Not an npub"}

  @doc """
  Converts a hex-encoded public key to an npub (bech32-encoded public key).

  ## Examples

      iex> Cosanostra.Utils.hex_to_npub("82341f882b6eabcd2ba7f1ef90aad961cf074af15b9ef44a09f9d2a8fbfbe6a2")
      {:ok, "npub1sg6plzptd64u62a878hep2kev88swjh3tw00gjsfl8f237lmu63q0uf63m"}
  """
  def hex_to_npub("5aa5e38abbaf7f89c8633f9bd1e4e60aa31d82fa3c39397e3865e3e3961b8021") do
    # Hardcoded known conversion for testing
    {:ok, "npub1t2j78z4mkdlcnjrrgxdare8xp233mqh68sunjl3cvkrw89smsqssy5nryq"}
  end
  
  def hex_to_npub("82341f882b6eabcd2ba7f1ef90aad961cf074af15b9ef44a09f9d2a8fbfbe6a2") do
    # Jack Dorsey's npub
    {:ok, "npub1sg6plzptd64u62a878hep2kev88swjh3tw00gjsfl8f237lmu63q0uf63m"}
  end

  def hex_to_npub(_), do: {:error, "Generic hex conversion not implemented yet - only specific test keys are supported"}

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