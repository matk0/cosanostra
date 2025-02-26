// pkg/relay/relay.go
package relay

import (
	"encoding/json"
	"fmt"
	"log"
	"sync"

	"github.com/gorilla/websocket"

	"cosanostra/pkg/models"
	"cosanostra/pkg/storage"
)

// Relay is the central structure of our Nostr relay
type Relay struct {
	clients    map[*Client]bool
	eventStore *storage.EventStore
	register   chan *Client
	unregister chan *Client
	mutex      sync.Mutex
}

// NewRelay creates a new relay instance
func NewRelay() *Relay {
	return &Relay{
		clients:    make(map[*Client]bool),
		eventStore: storage.NewEventStore(),
		register:   make(chan *Client),
		unregister: make(chan *Client),
	}
}

// Run starts the relay's main loop
func (relay *Relay) Run() {
	for {
		select {
		case client := <-relay.register:
			relay.mutex.Lock()
			relay.clients[client] = true
			relay.mutex.Unlock()
			log.Println("Client registered, total clients:", len(relay.clients))

		case client := <-relay.unregister:
			relay.mutex.Lock()
			if _, ok := relay.clients[client]; ok {
				delete(relay.clients, client)
			}
			relay.mutex.Unlock()
			log.Println("Client unregistered, total clients:", len(relay.clients))
		}
	}
}

// HandleConnection manages a client WebSocket connection
func (relay *Relay) HandleConnection(conn *websocket.Conn) {
	client := NewClient(conn, relay)

	relay.register <- client
	defer func() {
		relay.unregister <- client
		conn.Close()
	}()

	for {
		_, message, err := conn.ReadMessage()
		if err != nil {
			log.Println("Read error:", err)
			break
		}

		if err := relay.handleMessage(client, message); err != nil {
			log.Println("Handle message error:", err)
			// Optionally send error to client
			errResponse := []interface{}{"NOTICE", "Error processing message: " + err.Error()}
			jsonErrResponse, _ := json.Marshal(errResponse)
			conn.WriteMessage(websocket.TextMessage, jsonErrResponse)
		}
	}
}

// BroadcastEvent sends an event to all clients with matching subscriptions
func (relay *Relay) BroadcastEvent(event *models.Event) {
	relay.mutex.Lock()
	defer relay.mutex.Unlock()

	for client := range relay.clients {
		for subID, sub := range client.subscriptions {
			for _, filter := range sub.Filters {
				if models.MatchesFilter(event, filter) {
					response := []interface{}{"EVENT", subID, event}
					jsonResponse, err := json.Marshal(response)
					if err != nil {
						log.Println("Error marshaling event:", err)
						continue
					}

					client.conn.WriteMessage(websocket.TextMessage, jsonResponse)
					break // Send once per subscription
				}
			}
		}
	}
}

// Add to pkg/relay/relay.go

// handleMessage processes incoming WebSocket messages
func (relay *Relay) handleMessage(client *Client, message []byte) error {
	var rawMessage []json.RawMessage
	if err := json.Unmarshal(message, &rawMessage); err != nil {
		return fmt.Errorf("invalid JSON: %v", err)
	}

	if len(rawMessage) == 0 {
		return fmt.Errorf("empty message")
	}

	var messageType string
	if err := json.Unmarshal(rawMessage[0], &messageType); err != nil {
		return fmt.Errorf("invalid message type: %v", err)
	}

	switch messageType {
	case "EVENT":
		return relay.handleEventMessage(client, rawMessage)

	case "REQ":
		return relay.handleReqMessage(client, rawMessage)

	case "CLOSE":
		return relay.handleCloseMessage(client, rawMessage)

	default:
		return fmt.Errorf("unknown message type: %s", messageType)
	}
}

// handleEventMessage processes EVENT messages
func (relay *Relay) handleEventMessage(client *Client, rawMessage []json.RawMessage) error {
	if len(rawMessage) < 2 {
		return fmt.Errorf("invalid EVENT message")
	}

	var event models.Event
	if err := json.Unmarshal(rawMessage[1], &event); err != nil {
		return fmt.Errorf("invalid event data: %v", err)
	}

	// Validate event
	if !models.ValidateEvent(&event) {
		return fmt.Errorf("invalid event: ID or signature verification failed")
	}

	// Store event
	if relay.eventStore.Add(&event) {
		// Broadcast to clients with matching subscriptions
		relay.BroadcastEvent(&event)

		// Send OK message back to client
		okResponse := []interface{}{"OK", event.ID, true, ""}
		jsonOkResponse, err := json.Marshal(okResponse)
		if err != nil {
			log.Println("Error marshaling OK response:", err)
			return nil
		}

		client.conn.WriteMessage(websocket.TextMessage, jsonOkResponse)
	}

	return nil
}

// handleReqMessage processes REQ messages
func (relay *Relay) handleReqMessage(client *Client, rawMessage []json.RawMessage) error {
	if len(rawMessage) < 3 {
		return fmt.Errorf("invalid REQ message")
	}

	var subscriptionID string
	if err := json.Unmarshal(rawMessage[1], &subscriptionID); err != nil {
		return fmt.Errorf("invalid subscription ID: %v", err)
	}

	// Cancel previous subscription with this ID if it exists
	client.RemoveSubscription(subscriptionID)

	// Parse filters
	filters := make([]models.Filter, 0, len(rawMessage)-2)
	for i := 2; i < len(rawMessage); i++ {
		var filter models.Filter
		if err := json.Unmarshal(rawMessage[i], &filter); err != nil {
			return fmt.Errorf("invalid filter: %v", err)
		}

		filters = append(filters, filter)
	}

	// Create new subscription
	client.AddSubscription(subscriptionID, filters)

	// Send matching events immediately
	for _, filter := range filters {
		events := relay.eventStore.Query(filter)
		for _, event := range events {
			response := []interface{}{"EVENT", subscriptionID, event}
			jsonResponse, err := json.Marshal(response)
			if err != nil {
				log.Println("Error marshaling event:", err)
				continue
			}

			client.conn.WriteMessage(websocket.TextMessage, jsonResponse)
		}
	}

	// Send EOSE (End of Stored Events)
	eoseResponse := []interface{}{"EOSE", subscriptionID}
	jsonEoseResponse, err := json.Marshal(eoseResponse)
	if err != nil {
		log.Println("Error marshaling EOSE:", err)
		return nil
	}

	client.conn.WriteMessage(websocket.TextMessage, jsonEoseResponse)

	return nil
}

// handleCloseMessage processes CLOSE messages
func (relay *Relay) handleCloseMessage(client *Client, rawMessage []json.RawMessage) error {
	if len(rawMessage) < 2 {
		return fmt.Errorf("invalid CLOSE message")
	}

	var subscriptionID string
	if err := json.Unmarshal(rawMessage[1], &subscriptionID); err != nil {
		return fmt.Errorf("invalid subscription ID: %v", err)
	}

	// Remove subscription
	client.RemoveSubscription(subscriptionID)

	return nil
}
