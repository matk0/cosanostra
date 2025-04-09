# Cosanostra

A simple Elixir client for the Nostr protocol.

## Features

- Connect to Nostr relays via WebSockets
- Subscribe to Nostr events with filters
- Fetch and parse user profile metadata (kind 0 events)
- Utilities for working with Nostr public keys (hex/npub conversion)

## Installation

Add `cosanostra` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:cosanostra, "~> 0.1.0"}
  ]
end
```

## Usage

### Connecting to a Relay

```elixir
alias Cosanostra
alias Cosanostra.Relay

# Connect to a relay
{:ok, relay} = Cosanostra.connect("wss://relay.damus.io")

# Close the connection when done
Relay.close(relay)
```

### Fetching User Profiles

```elixir
# Fetch a profile using a hex-encoded public key
pubkey = "82341f882b6eabcd2ba7f1ef90aad961cf074af15b9ef44a09f9d2a8fbfbe6a2"
{:ok, profile} = Cosanostra.get_profile(relay, pubkey)

# Profile will contain fields like name, picture, about, etc.
IO.inspect(profile)
```

### Custom Subscriptions

You can create custom subscriptions to any type of events:

```elixir
# Create a filter for text notes (kind 1) from a specific user
filter = %{kinds: [1], authors: [pubkey], limit: 10}

# Subscribe to events matching the filter
subscription_id = Relay.subscribe(relay, filter)

# When done with the subscription
Relay.unsubscribe(relay, subscription_id)
```

### Working with Public Keys

The library provides utilities for working with Nostr public keys:

```elixir
alias Cosanostra.Utils

# Convert a hex-encoded public key to npub format
{:ok, npub} = Utils.hex_to_npub("82341f882b6eabcd2ba7f1ef90aad961cf074af15b9ef44a09f9d2a8fbfbe6a2")

# Convert an npub to hex format
{:ok, hex} = Utils.npub_to_hex("npub1sg6plzptd64u62a878hep2kev88swjh3tw00gjsfl8f237lmu63q0uf63m")

# Normalize a public key (accepts both formats)
{:ok, normalized} = Utils.normalize_pubkey(npub_or_hex)
```

## Examples

### Connecting to a relay and fetching a profile

```elixir
alias Cosanostra
alias Cosanostra.Relay

# Connect to a relay
{:ok, relay} = Cosanostra.connect("wss://relay.damus.io")

# Fetch Jack Dorsey's profile
pubkey = "82341f882b6eabcd2ba7f1ef90aad961cf074af15b9ef44a09f9d2a8fbfbe6a2"
{:ok, profile} = Cosanostra.get_profile(relay, pubkey)

# Print profile information
IO.puts("Name: #{profile["name"]}")
IO.puts("About: #{profile["about"]}")
IO.puts("Picture: #{profile["picture"]}")

# Close the connection
Relay.close(relay)
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.