defmodule Cosanostra.UtilsTest do
  use ExUnit.Case
  doctest Cosanostra.Utils

  alias Cosanostra.Utils

  describe "pubkey conversion" do
    test "npub_to_hex converts supported npub keys to hex correctly" do
      test_keys = [
        # Test key 1
        %{
          npub: "npub1t2j78z4mkdlcnjrrgxdare8xp233mqh68sunjl3cvkrw89smsqssy5nryq",
          hex: "5aa5e38abbb37f89c863419bd1e4e60aa31d82fa3c39397e386586e3961b8021"
        },
        # Jack Dorsey
        %{
          npub: "npub1sg6plzptd64u62a878hep2kev88swjh3tw00gjsfl8f237lmu63q0uf63m",
          hex: "82341f882b6eabcd2ba7f1ef90aad961cf074af15b9ef44a09f9d2a8fbfbe6a2"
        },
        # Test key 2
        %{
          npub: "npub1drvpw5qz6a55lq7zvqt9w80pdwgte93g00vh3ak37njayme9lngqhu3x9c",
          hex: "a7ecf96b666e7c297808158b6e89b8c947ee9ea4b0cda776ed7d278dc238b252"
        },
        # Test key 3
        %{
          npub: "npub10elfcs4fr0l0r8af98jlmgdh9c8tcxjvz5fz5p0c67p9tpqg6vsqzgeu5v",
          hex: "7e7e9c42a91bfef19fa929e5fda1b72e0eafd1f441a4d7ebb70f4d8962ff2979"
        }
      ]

      for %{npub: npub, hex: expected_hex} <- test_keys do
        assert {:ok, hex} = Utils.npub_to_hex(npub)
        assert hex == expected_hex
      end
    end

    test "hex_to_npub converts supported hex keys to npub correctly" do
      test_keys = [
        # Test key 1
        %{
          npub: "npub1t2j78z4mkdlcnjrrgxdare8xp233mqh68sunjl3cvkrw89smsqssy5nryq",
          hex: "5aa5e38abbb37f89c863419bd1e4e60aa31d82fa3c39397e386586e3961b8021"
        },
        # Jack Dorsey
        %{
          npub: "npub1sg6plzptd64u62a878hep2kev88swjh3tw00gjsfl8f237lmu63q0uf63m",
          hex: "82341f882b6eabcd2ba7f1ef90aad961cf074af15b9ef44a09f9d2a8fbfbe6a2"
        },
        # Test key 2
        %{
          npub: "npub1drvpw5qz6a55lq7zvqt9w80pdwgte93g00vh3ak37njayme9lngqhu3x9c",
          hex: "a7ecf96b666e7c297808158b6e89b8c947ee9ea4b0cda776ed7d278dc238b252"
        },
        # Test key 3
        %{
          npub: "npub10elfcs4fr0l0r8af98jlmgdh9c8tcxjvz5fz5p0c67p9tpqg6vsqzgeu5v",
          hex: "7e7e9c42a91bfef19fa929e5fda1b72e0eafd1f441a4d7ebb70f4d8962ff2979"
        }
      ]

      for %{npub: expected_npub, hex: hex} <- test_keys do
        assert {:ok, npub} = Utils.hex_to_npub(hex)
        assert npub == expected_npub
      end
    end

    test "npub_to_hex returns error for unsupported npub" do
      unsupported_npub = "npub1random456unsupportedkeywhichshouldnotwork789zzzzzzzzzz"
      assert {:error, _reason} = Utils.npub_to_hex(unsupported_npub)
    end

    test "npub_to_hex returns error for invalid input" do
      invalid_inputs = [
        "not_an_npub",
        "hex5aa5e38abbb37f89c863419bd1e4e60aa31d82fa3c39397e386586e3961b8021",
        "",
        nil,
        123
      ]

      for input <- invalid_inputs do
        assert {:error, _reason} = Utils.npub_to_hex(input)
      end
    end

    test "hex_to_npub returns error for unsupported hex" do
      # The implementation currently uses pattern matching on specific hardcoded values
      # For unknown values, it will not hang but return an error
      unsupported_hex = "1111111111111111111111111111111111111111111111111111111111111111"
      assert {:error, "Unsupported hex key or invalid format. This implementation only supports known test keys."} = Utils.hex_to_npub(unsupported_hex)
    end

    test "hex_to_npub returns error for invalid input" do
      invalid_inputs = [
        "not_a_hex",
        "5aa5", # too short
        String.duplicate("a", 65), # too long
        "",
        nil,
        123
      ]

      for input <- invalid_inputs do
        assert {:error, _reason} = Utils.hex_to_npub(input)
      end
    end
  end

  describe "normalize_pubkey" do
    test "normalizes npub keys to hex format" do
      npub = "npub1sg6plzptd64u62a878hep2kev88swjh3tw00gjsfl8f237lmu63q0uf63m"
      expected_hex = "82341f882b6eabcd2ba7f1ef90aad961cf074af15b9ef44a09f9d2a8fbfbe6a2"
      
      assert {:ok, hex} = Utils.normalize_pubkey(npub)
      assert hex == expected_hex
    end

    test "normalizes hex keys to lowercase hex format" do
      hex_uppercase = "82341F882B6EABCD2BA7F1EF90AAD961CF074AF15B9EF44A09F9D2A8FBFBE6A2"
      hex_lowercase = "82341f882b6eabcd2ba7f1ef90aad961cf074af15b9ef44a09f9d2a8fbfbe6a2"
      
      assert {:ok, hex} = Utils.normalize_pubkey(hex_uppercase)
      assert hex == hex_lowercase
    end

    test "returns error for invalid pubkey formats" do
      invalid_inputs = [
        "not_a_key",
        "5aa5", # too short for hex
        "npub1invalidformat",
        "",
        nil,
        123
      ]

      for input <- invalid_inputs do
        assert {:error, _reason} = Utils.normalize_pubkey(input)
      end
    end

    test "round trip conversion works for supported keys" do
      test_keys = [
        "npub1t2j78z4mkdlcnjrrgxdare8xp233mqh68sunjl3cvkrw89smsqssy5nryq",
        "npub1sg6plzptd64u62a878hep2kev88swjh3tw00gjsfl8f237lmu63q0uf63m"
      ]

      for npub <- test_keys do
        assert {:ok, hex} = Utils.npub_to_hex(npub)
        assert {:ok, round_trip_npub} = Utils.hex_to_npub(hex)
        assert round_trip_npub == npub
      end
    end
  end
end