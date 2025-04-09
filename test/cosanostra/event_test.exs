defmodule Cosanostra.EventTest do
  use ExUnit.Case
  doctest Cosanostra.Event

  alias Cosanostra.Event

  describe "Event.from_map/1" do
    test "creates an event from a map" do
      attrs = %{
        "id" => "test_id_123",
        "pubkey" => "test_pubkey_456",
        "created_at" => 1612345678,
        "kind" => 0,
        "tags" => [["e", "event_ref"], ["p", "pubkey_ref"]],
        "content" => ~s({"name":"Test User","about":"This is a test"}),
        "sig" => "test_signature_789"
      }

      event = Event.from_map(attrs)

      assert event.id == attrs["id"]
      assert event.pubkey == attrs["pubkey"]
      assert event.created_at == attrs["created_at"]
      assert event.kind == attrs["kind"]
      assert event.tags == attrs["tags"]
      assert event.content == attrs["content"]
      assert event.sig == attrs["sig"]
    end

    test "returns error for missing required fields" do
      # Create incomplete event map
      attrs = %{
        "id" => "test_id_123",
        "pubkey" => "test_pubkey_456",
        "kind" => 0
        # Missing created_at, tags, content, sig
      }

      result = Event.from_map(attrs)
      assert {:error, _reason} = result
    end
  end

  describe "Event.parse_metadata/1" do
    test "parses valid metadata" do
      content = ~s({"name":"Test User","about":"This is a test"})
      event = %Event{
        id: "test_id_123",
        pubkey: "test_pubkey_456",
        created_at: 1612345678,
        kind: 0,
        tags: [],
        content: content,
        sig: "test_sig"
      }

      assert {:ok, profile} = Event.parse_metadata(event)
      assert profile["name"] == "Test User"
      assert profile["about"] == "This is a test"
      assert profile["created_at"] == 1612345678
      assert profile["event_id"] == "test_id_123"
    end

    test "adds created_at to profile data if not present" do
      content = ~s({"name":"Test User"})
      event = %Event{
        id: "test_id_123",
        pubkey: "test_pubkey_456",
        created_at: 1612345678,
        kind: 0,
        tags: [],
        content: content,
        sig: "test_sig"
      }

      assert {:ok, profile} = Event.parse_metadata(event)
      assert profile["name"] == "Test User"
      assert profile["created_at"] == 1612345678
    end

    test "adds event_id to profile data" do
      content = ~s({"name":"Test User"})
      event = %Event{
        id: "test_id_123",
        pubkey: "test_pubkey_456",
        created_at: 1612345678,
        kind: 0,
        tags: [],
        content: content,
        sig: "test_sig"
      }

      assert {:ok, profile} = Event.parse_metadata(event)
      assert profile["event_id"] == "test_id_123"
    end

    test "returns error for invalid JSON" do
      content = ~s({invalid json)
      event = %Event{
        id: "test_id_123",
        pubkey: "test_pubkey_456",
        created_at: 1612345678,
        kind: 0,
        tags: [],
        content: content,
        sig: "test_sig"
      }

      assert {:error, _} = Event.parse_metadata(event)
    end

    test "returns error for non-metadata events" do
      content = ~s({"name":"Test User"})
      event = %Event{
        id: "test_id_123",
        pubkey: "test_pubkey_456",
        created_at: 1612345678,
        kind: 1, # Not kind 0 (metadata)
        tags: [],
        content: content,
        sig: "test_sig"
      }

      assert {:error, _} = Event.parse_metadata(event)
    end
  end

  describe "Event.metadata?/1" do
    test "returns true for metadata events" do
      event = %Event{
        id: "test_id_123",
        pubkey: "test_pubkey_456",
        created_at: 1612345678,
        kind: 0,
        tags: [],
        content: "",
        sig: "test_sig"
      }

      assert Event.metadata?(event)
    end

    test "returns false for non-metadata events" do
      event = %Event{
        id: "test_id_123",
        pubkey: "test_pubkey_456",
        created_at: 1612345678,
        kind: 1,
        tags: [],
        content: "",
        sig: "test_sig"
      }

      assert !Event.metadata?(event)
    end
  end
end