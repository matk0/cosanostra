defmodule Cosanostra.Event do
  @moduledoc """
  Defines Nostr event types and functions for working with events.
  """

  @enforce_keys [:id, :pubkey, :created_at, :kind, :tags, :content, :sig]
  defstruct [:id, :pubkey, :created_at, :kind, :tags, :content, :sig]

  @doc """
  Creates an event struct from a map.

  ## Examples

      event = Cosanostra.Event.from_map(%{
        "id" => "abc123",
        "pubkey" => "def456",
        "created_at" => 1612412012,
        "kind" => 0,
        "tags" => [],
        "content" => "{\\"name\\":\\"username\\"}",
        "sig" => "signature"
      })
  """
  def from_map(map) when is_map(map) do
    keys = ["id", "pubkey", "created_at", "kind", "tags", "content", "sig"]
    
    if Enum.all?(keys, &Map.has_key?(map, &1)) do
      %__MODULE__{
        id: map["id"],
        pubkey: map["pubkey"],
        created_at: map["created_at"],
        kind: map["kind"],
        tags: map["tags"],
        content: map["content"],
        sig: map["sig"]
      }
    else
      missing = Enum.filter(keys, &(not Map.has_key?(map, &1)))
      {:error, "Missing required fields: #{inspect(missing)}"}
    end
  end

  @doc """
  Parses the content of a kind 0 (metadata) event.

  ## Examples

      {:ok, metadata} = Cosanostra.Event.parse_metadata(event)
      metadata.name # => "username"
  """
  def parse_metadata(%__MODULE__{kind: 0, content: content}) do
    case Jason.decode(content) do
      {:ok, parsed} -> {:ok, parsed}
      error -> error
    end
  end
  def parse_metadata(_), do: {:error, "Not a metadata event"}
  
  @doc """
  Returns true if the event is a metadata event (kind 0).
  """
  def metadata?(%__MODULE__{kind: 0}), do: true
  def metadata?(_), do: false

  @doc """
  Returns true if the event is a text note (kind 1).
  """
  def text_note?(%__MODULE__{kind: 1}), do: true
  def text_note?(_), do: false
end