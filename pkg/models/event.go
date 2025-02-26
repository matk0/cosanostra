package models

type Event struct {
	ID        string     `json:"id"`
	PubKey    string     `json:"pubkey"`
	CreatedAt int64      `json:"created_at"`
	Kind      int        `json:"kind"`
	Tags      [][]string `json:"tags"`
	Content   string     `json:"content"`
	Sig       string     `json:"sig"`
}

type SubscriptionRequest struct {
	Filters []Filter `json:"filters"`
}

type Filter struct {
	IDs     []string `json:"ids,omitempty"`
	Authors []string `json:"authors,omitempty"`
	Kinds   []int    `json:"kinds,omitempty"`
	Since   int64    `json:"since,omitempty"`
	Until   int64    `json:"until,omitempty"`
	Limit   int      `json:"limit,omitempty"`
}

type Message struct {
	Type           string               `json:"type,omitempty"`
	SubscriptionId string               `json:"subscription_id,omitempty"`
	Event          *Event               `json:"event,omitempty"`
	Filter         *SubscriptionRequest `json:"filter,omitempty"`
}
