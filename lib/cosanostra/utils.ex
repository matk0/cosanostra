defmodule Cosanostra.Utils do
  @moduledoc """
  Utility functions for working with Nostr.
  """
  @doc """
  Converts an npub (bech32-encoded public key) to a hex-encoded public key.

  ## Examples

      iex> Cosanostra.Utils.npub_to_hex("npub1t2j78z4mkdlcnjrrgxdare8xp233mqh68sunjl3cvkrw89smsqssy5nryq")
      {:ok, "8c0da4862130283ff9e67d889df264177a508974e2feb96de139804ea66d6168"}
  """
  def npub_to_hex("npub" <> _ = npub) do
    case Bech32.decode(npub) do
      {:ok, "npub", data} ->
        # Convert 5-bit data to 8-bit bytes
        bytes = Bech32.convertbits(data, 5, 8, false)
        hex = Base.encode16(bytes, case: :lower)
        {:ok, hex}
      
      {:error, reason} ->
        {:error, "Invalid npub: #{reason}"}
        
      _ ->
        {:error, "Invalid npub format"}
    end
  end

  def npub_to_hex(_), do: {:error, "Not an npub"}

  @doc """
  Converts a hex-encoded public key to an npub (bech32-encoded public key).

  ## Examples

      iex> Cosanostra.Utils.hex_to_npub("8c0da4862130283ff9e67d889df264177a508974e2feb96de139804ea66d6168")
      {:ok, "npub1t2j78z4mkdlcnjrrgxdare8xp233mqh68sunjl3cvkrw89smsqssy5nryq"}
  """
  def hex_to_npub(hex) when is_binary(hex) do
    case Base.decode16(hex, case: :mixed) do
      {:ok, decoded} ->
        # Convert 8-bit bytes to 5-bit data
        data = Bech32.convertbits(decoded, 8, 5, true)
        {:ok, Bech32.encode("npub", data)}
        
      :error ->
        {:error, "Invalid hex format"}
    end
  end

  @doc """
  Normalizes a public key, converting from npub to hex if needed.

  ## Examples

      iex> Cosanostra.Utils.normalize_pubkey("npub1t2j78z4mkdlcnjrrgxdare8xp233mqh68sunjl3cvkrw89smsqssy5nryq")
      {:ok, "8c0da4862130283ff9e67d889df264177a508974e2feb96de139804ea66d6168"}

      iex> Cosanostra.Utils.normalize_pubkey("8c0da4862130283ff9e67d889df264177a508974e2feb96de139804ea66d6168")
      {:ok, "8c0da4862130283ff9e67d889df264177a508974e2feb96de139804ea66d6168"}
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