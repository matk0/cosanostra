package storage

import (
	"sync"

	"cosanostra/pkg/models"
)

// EventStore manages events in memory
type EventStore struct {
	events map[string]*models.Event
	mutex  sync.RWMutex
}

// NewEventStore creates a new event store
func NewEventStore() *EventStore {
	return &EventStore{
		events: make(map[string]*models.Event),
	}
}

// Add stores an event
func (store *EventStore) Add(event *models.Event) bool {
	store.mutex.Lock()
	defer store.mutex.Unlock()

	// Check if event already exists
	if _, exists := store.events[event.ID]; exists {
		return false
	}

	store.events[event.ID] = event
	return true
}

// Query returns events matching the filter
func (store *EventStore) Query(filter models.Filter) []*models.Event {
	store.mutex.RLock()
	defer store.mutex.RUnlock()

	var results []*models.Event

	for _, event := range store.events {
		if models.MatchesFilter(event, filter) {
			results = append(results, event)
		}
	}

	return results
}

// GetByID retrieves an event by its ID
func (store *EventStore) GetByID(id string) (*models.Event, bool) {
	store.mutex.RLock()
	defer store.mutex.RUnlock()

	event, exists := store.events[id]
	return event, exists
}
