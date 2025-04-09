# Cosanostra

A minimal Elixir client for the Nostr protocol. Currently focused on connecting to relays and fetching user metadata (profiles).

## Current Features

- Connect to Nostr relays using WebSockets
- Subscribe to Nostr events with filters
- Fetch user profile metadata (kind 0 events) from multiple relays in parallel
- Select the most recent profile based on timestamp when querying multiple relays
- Enrich profile data with event metadata (created_at timestamp and event_id)
- Basic conversion between npub and hex-encoded public keys (limited to specific test keys)

## Limitations

- npub/hex conversion is currently limited to specific hardcoded test keys
- Only supports fetching metadata (kind 0) events
- Does not support event creation or signing

## Installation

Add `cosanostra` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:cosanostra, "~> 0.1.0"}
  ]
end
```

## Connecting to Relays

Use `Cosanostra.connect/2` to connect to a relay:

```elixir
alias Cosanostra
alias Cosanostra.Relay

# Connect with default timeout (5 seconds)
case Cosanostra.connect("wss://relay.damus.io") do
  {:ok, relay} ->
    # Use the relay...
    
  {:error, reason} ->
    # Handle connection error
end

# Connect with a custom timeout (10 seconds)
{:ok, relay} = Cosanostra.connect("wss://relay.damus.io", 10000)

# Always close the connection when done
Relay.close(relay)
```

## Fetching User Profiles

There are two ways to fetch user profiles:

### From a single relay:

```elixir
# Using a hex key
{:ok, relay} = Cosanostra.connect("wss://relay.damus.io")
{:ok, profile} = Cosanostra.get_profile(relay, "82341f882b6eabcd2ba7f1ef90aad961cf074af15b9ef44a09f9d2a8fbfbe6a2")

# Using npub format (for supported keys only)
{:ok, profile} = Cosanostra.get_profile(relay, "npub1sg6plzptd64u62a878hep2kev88swjh3tw00gjsfl8f237lmu63q0uf63m")
```

Note: When querying relays, all pubkeys are automatically normalized to hex format before sending the request. This happens whether you provide an npub or hex key as input.

The library automatically enriches profile data with additional fields from the event metadata:
- `created_at`: Taken from the event's timestamp
- `event_id`: The Nostr event ID that contained the profile data

### From multiple relays at once:

```elixir
# This tries multiple default relays and returns the most recent profile found
# (based on the created_at timestamp)
{:ok, profile} = Cosanostra.get_profile_from_relays("82341f882b6eabcd2ba7f1ef90aad961cf074af15b9ef44a09f9d2a8fbfbe6a2")

# With custom relays
relays = [
  "wss://relay.damus.io",
  "wss://relay.nostr.band",
  "wss://nos.lol",
  "wss://purplepag.es/",
  "wss://pyramid.fiatjaf.com/",
  "wss://relay.primal.net/"
]
{:ok, profile} = Cosanostra.get_profile_from_relays("82341f882b6eabcd2ba7f1ef90aad961cf074af15b9ef44a09f9d2a8fbfbe6a2", relays)

# With custom timeout (milliseconds)
{:ok, profile} = Cosanostra.get_profile_from_relays("82341f882b6eabcd2ba7f1ef90aad961cf074af15b9ef44a09f9d2a8fbfbe6a2", relays, 10000)
```

## Profile Data Structure

A successful profile request returns a map with profile fields:

```elixir
{:ok, profile} = Cosanostra.get_profile_from_relays(pubkey)

# The profile contains fields like:
# - name: User's display name
# - picture: URL to profile picture
# - about: User's bio
# - nip05: NIP-05 verification string
# - created_at: Timestamp when the profile was created (Unix timestamp)
# - event_id: ID of the Nostr event that contained this profile data
# And possibly other custom fields
```

## Custom Subscriptions

For more advanced use cases, you can create custom subscriptions:

```elixir
# Connect to a relay
{:ok, relay} = Cosanostra.connect("wss://relay.damus.io")

# Create a subscription for text notes (kind 1) from a specific user
filter = %{kinds: [1], authors: [pubkey], limit: 10}

# Subscribe and register the current process to receive events
subscription_id = Relay.subscribe(relay, filter, nil, self())

# Receive events in your process
receive do
  {:event, ^subscription_id, event} ->
    IO.inspect(event, label: "Received event")
    
  {:eose, ^subscription_id} ->
    IO.puts("End of stored events")
after
  5000 -> IO.puts("Timeout")
end

# Unsubscribe when done
Relay.unsubscribe(relay, subscription_id)

# Close the relay connection
Relay.close(relay)
```

## Public Key Utilities

The `Cosanostra.Utils` module provides functions for working with public keys:

```elixir
alias Cosanostra.Utils

# Convert npub to hex (only works with supported test keys)
{:ok, hex} = Utils.npub_to_hex("npub1sg6plzptd64u62a878hep2kev88swjh3tw00gjsfl8f237lmu63q0uf63m")
# => {:ok, "82341f882b6eabcd2ba7f1ef90aad961cf074af15b9ef44a09f9d2a8fbfbe6a2"}

# Convert hex to npub (only works with supported test keys)
{:ok, npub} = Utils.hex_to_npub("82341f882b6eabcd2ba7f1ef90aad961cf074af15b9ef44a09f9d2a8fbfbe6a2")
# => {:ok, "npub1sg6plzptd64u62a878hep2kev88swjh3tw00gjsfl8f237lmu63q0uf63m"}

# Normalize a public key to hex format (works with both formats for supported keys)
{:ok, hex} = Utils.normalize_pubkey(npub_or_hex)
```

### Currently Supported Test Keys

- Jack Dorsey's public key:
  - npub: `npub1sg6plzptd64u62a878hep2kev88swjh3tw00gjsfl8f237lmu63q0uf63m`
  - hex: `82341f882b6eabcd2ba7f1ef90aad961cf074af15b9ef44a09f9d2a8fbfbe6a2`

- Test key 1:
  - npub: `npub1t2j78z4mkdlcnjrrgxdare8xp233mqh68sunjl3cvkrw89smsqssy5nryq`
  - hex: `5aa5e38abbb37f89c863419bd1e4e60aa31d82fa3c39397e386586e3961b8021`

- Test key 2:
  - npub: `npub1drvpw5qz6a55lq7zvqt9w80pdwgte93g00vh3ak37njayme9lngqhu3x9c`
  - hex: `a7ecf96b666e7c297808158b6e89b8c947ee9ea4b0cda776ed7d278dc238b252`

- Test key 3:
  - npub: `npub10elfcs4fr0l0r8af98jlmgdh9c8tcxjvz5fz5p0c67p9tpqg6vsqzgeu5v`
  - hex: `7e7e9c42a91bfef19fa929e5fda1b72e0eafd1f441a4d7ebb70f4d8962ff2979`

## Complete Example

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

# Print timestamp information
created_at = profile["created_at"]
{:ok, datetime} = DateTime.from_unix(created_at)
IO.puts("Created at: #{datetime} (#{created_at})")

# Print event ID
IO.puts("Event ID: #{profile["event_id"]}")

# Close the connection
Relay.close(relay)
```

## Error Handling

Functions return error tuples in various situations:

```elixir
# Relay connection errors
{:error, :timeout}             # Connection to relay timed out
{:error, %WebSockex.ConnError} # WebSocket connection error

# Profile retrieval errors
{:error, :timeout}             # Request for profile data timed out
{:error, :not_found}           # Profile not found on the relay(s)
{:error, :no_relays_connected} # Could not connect to any relays

# Public key conversion errors
{:error, "Not an npub format"}        # Input wasn't an npub
{:error, "Invalid hex format: must be 64 characters"} # Input wasn't a valid hex-encoded key
{:error, "Unsupported npub key. This implementation only supports known test keys."} # Unsupported npub
{:error, "Unsupported hex key or invalid format. This implementation only supports known test keys."} # Unsupported hex

# Generic errors
{:error, reason}               # Other errors with reason
```

Always pattern match on error tuples using a catch-all case to handle unexpected errors.

## Development Status

This library is in early development stage and not all features of the Nostr protocol are implemented yet.

## License

This project is licensed under the MIT License.