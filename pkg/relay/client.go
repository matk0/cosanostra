// pkg/relay/client.go
package relay

import (
	"github.com/gorilla/websocket"

	"cosanostra/pkg/models"
)

// Subscription represents a client subscription
type Subscription struct {
	ID      string
	Filters []models.Filter
	Client  *Client
}

// Client represents a connected client
type Client struct {
	conn          *websocket.Conn
	subscriptions map[string]*Subscription
	relay         *Relay // This will be a circular reference
}

// NewClient creates a new client
func NewClient(conn *websocket.Conn, relay *Relay) *Client {
	return &Client{
		conn:          conn,
		subscriptions: make(map[string]*Subscription),
		relay:         relay,
	}
}

// AddSubscription adds a new subscription for this client
func (client *Client) AddSubscription(id string, filters []models.Filter) *Subscription {
	subscription := &Subscription{
		ID:      id,
		Filters: filters,
		Client:  client,
	}

	client.subscriptions[id] = subscription
	return subscription
}

// RemoveSubscription removes a subscription by ID
func (client *Client) RemoveSubscription(id string) {
	delete(client.subscriptions, id)
}
