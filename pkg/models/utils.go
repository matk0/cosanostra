package models

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"

	"github.com/btcsuite/btcd/btcec/v2/schnorr"
)

// ValidateEvent checks if an event's ID matches its content hash and validates the signature
func ValidateEvent(event *Event) bool {
	// For testing purposes, let's bypass validation temporarily
	// Comment this out when your relay is ready for production
	// fmt.Println("WARNING: Bypassing validation for testing purposes")
	// return true

	// First, check if the event ID is correct (SHA256 hash of the serialized event)
	serialized, err := SerializeEvent(event)
	if err != nil {
		fmt.Printf("Failed to serialize event: %v\n", err)
		return false
	}

	hash := sha256.Sum256([]byte(serialized))
	computedID := hex.EncodeToString(hash[:])

	fmt.Printf("Computed ID: %s\n", computedID)
	fmt.Printf("Event ID: %s\n", event.ID)

	if computedID != event.ID {
		fmt.Printf("ID mismatch. Expected: %s, Got: %s\n", computedID, event.ID)
		return false
	}

	// Next, verify the signature
	pubKeyBytes, err := hex.DecodeString(event.PubKey)
	if err != nil {
		fmt.Printf("Failed to decode pubkey: %v\n", err)
		return false
	}

	sigBytes, err := hex.DecodeString(event.Sig)
	if err != nil {
		fmt.Printf("Failed to decode signature: %v\n", err)
		return false
	}

	// For Nostr, we need to convert the 32-byte pubkey to a valid secp256k1 public key
	// Nostr uses the 32-byte x-coordinate of the public key point
	if len(pubKeyBytes) != 32 {
		fmt.Printf("Failed to parse pubkey: malformed public key: invalid length: %d\n", len(pubKeyBytes))
		return false
	}

	// Create a public key from the x-coordinate only (with y=even)
	pubKeyObj, err := schnorr.ParsePubKey(pubKeyBytes)
	if err != nil {
		fmt.Printf("Failed to parse pubkey: %v\n", err)
		return false
	}

	// Parse the signature
	signature, err := schnorr.ParseSignature(sigBytes)
	if err != nil {
		fmt.Printf("Failed to parse signature: %v\n", err)
		return false
	}

	// In Nostr, we sign the event ID itself
	messageHashBytes, err := hex.DecodeString(event.ID)
	if err != nil {
		fmt.Printf("Failed to decode event ID for verification: %v\n", err)
		return false
	}

	// Verify the signature using the Signature.Verify method
	verified := signature.Verify(messageHashBytes, pubKeyObj)

	if !verified {
		fmt.Printf("Signature verification failed\n")
	}

	return verified
}

// SerializeEvent creates the canonical form of an event for hashing according to NIP-01
func SerializeEvent(event *Event) (string, error) {
	// This is the canonical serialization format from NIP-01
	// [0, pubkey, created_at, kind, tags, content]

	// Properly escape content according to requirements
	content := escapeContentField(event.Content)

	arr := []interface{}{
		0,
		event.PubKey,
		event.CreatedAt,
		event.Kind,
		event.Tags,
		content,
	}

	// Use json.Marshal with SetEscapeHTML(false) to avoid unnecessary escaping
	buffer := &bytes.Buffer{}
	encoder := json.NewEncoder(buffer)
	encoder.SetEscapeHTML(false)
	err := encoder.Encode(arr)
	if err != nil {
		return "", err
	}

	// Remove the trailing newline that json.Encoder adds
	serialized := buffer.Bytes()
	if len(serialized) > 0 && serialized[len(serialized)-1] == '\n' {
		serialized = serialized[:len(serialized)-1]
	}

	return string(serialized), nil
}

// escapeContentField properly escapes specific characters in content field
// according to the requirements:
// - Line break (0x0A): \n
// - Double quote (0x22): \"
// - Backslash (0x5C): \\
// - Carriage return (0x0D): \r
// - Tab character (0x09): \t
// - Backspace (0x08): \b
// - Form feed (0x0C): \f
func escapeContentField(content string) string {
	// Note: json.Marshal will handle the escaping for these characters correctly
	// We use the standard library's JSON marshaling which follows the JSON spec
	// for character escaping, which aligns with the requirements
	return content
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

// For debugging: helper function to validate events with bypass option
func DebugValidateEvent(event *Event, bypassSignature bool) bool {
	// First, check if the event ID is correct (SHA256 hash of the serialized event)
	println(SerializeEvent(event))
	serialized, err := SerializeEvent(event)
	if err != nil {
		fmt.Printf("Failed to serialize event: %v\n", err)
		return false
	}

	hash := sha256.Sum256([]byte(serialized))
	computedID := hex.EncodeToString(hash[:])

	fmt.Printf("Serialized event: %s\n", serialized)
	fmt.Printf("Computed ID: %s\n", computedID)
	fmt.Printf("Event ID: %s\n", event.ID)

	if computedID != event.ID {
		fmt.Printf("ID mismatch. Expected: %s, Got: %s\n", computedID, event.ID)
		return false
	}

	if bypassSignature {
		fmt.Println("Bypassing signature verification")
		return true
	}

	// Next, verify the signature
	pubKeyBytes, err := hex.DecodeString(event.PubKey)
	if err != nil {
		fmt.Printf("Failed to decode pubkey: %v\n", err)
		return false
	}

	sigBytes, err := hex.DecodeString(event.Sig)
	if err != nil {
		fmt.Printf("Failed to decode signature: %v\n", err)
		return false
	}

	// For Nostr, we need to convert the 32-byte pubkey to a valid secp256k1 public key
	// Nostr uses the 32-byte x-coordinate of the public key point
	if len(pubKeyBytes) != 32 {
		fmt.Printf("Failed to parse pubkey: malformed public key: invalid length: %d\n", len(pubKeyBytes))
		return false
	}

	// Create a public key from the x-coordinate only (with y=even)
	pubKey, err := schnorr.ParsePubKey(pubKeyBytes)
	if err != nil {
		fmt.Printf("Failed to parse pubkey: %v\n", err)
		return false
	}

	// Parse the signature
	signature, err := schnorr.ParseSignature(sigBytes)
	if err != nil {
		fmt.Printf("Failed to parse signature: %v\n", err)
		return false
	}

	// In Nostr, we sign the event ID itself
	messageHashBytes, err := hex.DecodeString(event.ID)
	if err != nil {
		fmt.Printf("Failed to decode event ID for verification: %v\n", err)
		return false
	}

	// Verify the signature
	verified := signature.Verify(messageHashBytes, pubKey)

	fmt.Printf("Signature verification result: %v\n", verified)

	return verified
}
