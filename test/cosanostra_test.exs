defmodule CosanostraTest do
  use ExUnit.Case
  doctest Cosanostra

  alias Cosanostra.Utils

  describe "pubkey handling" do
    test "normalize_pubkey properly converts between npub and hex formats" do
      # This is a simpler test just to verify the integration between modules
      test_pairs = [
        {"npub1t2j78z4mkdlcnjrrgxdare8xp233mqh68sunjl3cvkrw89smsqssy5nryq", 
         "5aa5e38abbb37f89c863419bd1e4e60aa31d82fa3c39397e386586e3961b8021"},
        {"npub1sg6plzptd64u62a878hep2kev88swjh3tw00gjsfl8f237lmu63q0uf63m", 
         "82341f882b6eabcd2ba7f1ef90aad961cf074af15b9ef44a09f9d2a8fbfbe6a2"}
      ]
      
      for {npub, hex} <- test_pairs do
        # Verify npub to hex
        assert {:ok, ^hex} = Utils.normalize_pubkey(npub)
        
        # Verify hex remains hex
        assert {:ok, ^hex} = Utils.normalize_pubkey(hex)
        
        # Verify uppercase hex normalizes to lowercase
        uppercase_hex = String.upcase(hex)
        assert {:ok, ^hex} = Utils.normalize_pubkey(uppercase_hex)
      end
    end
  end

  # Note: Additional integration tests for get_profile and get_profile_from_relays
  # would require either mocking the WebSocket connections or connecting to 
  # real Nostr relays, which is better suited for integration tests
  # rather than unit tests. The focus here is on unit testing the 
  # pubkey conversion and normalization functionality.
end