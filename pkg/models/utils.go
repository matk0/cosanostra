package models

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"github.com/btcsuite/btcd/btcec/v2"
	"github.com/btcsuite/btcd/btcec/v2/schnorr"
)

// ValidateEvent checks if an event's ID matches its content hash and validates the signature
func ValidateEvent(event *Event) bool {
	// Check if ID is correct
	serialized, err := SerializeEvent(event)
	if err != nil {
		return false
	}

	hash := sha256.Sum256([]byte(serialized))
	expectedID := hex.EncodeToString(hash[:])

	// Verify ID matches content hash
	if event.ID != expectedID {
		return false
	}

	// Verify signature
	messageHash := sha256.Sum256([]byte(event.ID))

	// Decode the public key from hex
	pubKeyBytes, err := hex.DecodeString(event.PubKey)
	if err != nil {
		return false
	}

	// Parse the public key
	pubKey, err := schnorr.ParsePubKey(pubKeyBytes)
	if err != nil {
		return false
	}

	// Decode the signature from hex
	sigBytes, err := hex.DecodeString(event.Sig)
	if err != nil {
		return false
	}

	// Verify the signature
	return schnorr.Verify(sigBytes, messageHash[:], pubKey)
}

// SerializeEvent creates the canonical form of an event for hashing
func SerializeEvent(event *Event) (string, error) {
	// Create array for serialization according to NIP-01
	arr := []interface{}{
		0,
		event.PubKey,
		event.CreatedAt,
		event.Kind,
		event.Tags,
		event.Content,
	}

	serialized, err := json.Marshal(arr)
	if err != nil {
		return "", err
	}

	return string(serialized), nil
}

// MatchesFilter checks if an event matches a specified filter
func MatchesFilter(event *Event, filter Filter) bool {
	// If IDs filter is specified, check if event ID is in the list
	if len(filter.IDs) > 0 {
		found := false
		for _, id := range filter.IDs {
			if event.ID == id {
				found = true
				break
			}
		}
		if !found {
			return false
		}
	}

	// If Authors filter is specified, check if event author is in the list
	if len(filter.Authors) > 0 {
		found := false
		for _, author := range filter.Authors {
			if event.PubKey == author {
				found = true
				break
			}
		}
		if !found {
			return false
		}
	}

	// If Kinds filter is specified, check if event kind is in the list
	if len(filter.Kinds) > 0 {
		found := false
		for _, kind := range filter.Kinds {
			if event.Kind == kind {
				found = true
				break
			}
		}
		if !found {
			return false
		}
	}

	// Check time-based filters
	if filter.Since > 0 && event.CreatedAt < filter.Since {
		return false
	}

	if filter.Until > 0 && event.CreatedAt > filter.Until {
		return false
	}

	return true
}
