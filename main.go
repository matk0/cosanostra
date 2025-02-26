package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"

	"cosanostra/pkg/models"

	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true // !!! Allow connections from any origin for now. !!!
	},
}

func handleWebSocket(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println("Connection upgrade error: ", err)
		return
	}
	defer conn.Close()

	fmt.Println("New client connected!")

	for {
		_, message, err := conn.ReadMessage()
		if err != nil {
			log.Println("Message read error: ", err)
			break
		}

		fmt.Printf("Received: %s\n", message)

		// Parse the message as a Nostr protocol message (array format)
		var rawMessage []json.RawMessage
		if err := json.Unmarshal(message, &rawMessage); err != nil {
			errMsg := fmt.Sprintf(`["NOTICE", "Error processing message: invalid JSON: %s"]`, err.Error())
			conn.WriteMessage(websocket.TextMessage, []byte(errMsg))
			continue
		}

		// Ensure we have at least the message type
		if len(rawMessage) < 1 {
			conn.WriteMessage(websocket.TextMessage, []byte(`["NOTICE", "Error: Invalid message format"]`))
			continue
		}

		// Extract the message type (first element in array)
		var messageType string
		if err := json.Unmarshal(rawMessage[0], &messageType); err != nil {
			conn.WriteMessage(websocket.TextMessage, []byte(`["NOTICE", "Error: Invalid message type"]`))
			continue
		}

		// Handle the message based on its type
		switch messageType {
		case "EVENT":
			if len(rawMessage) < 2 {
				conn.WriteMessage(websocket.TextMessage, []byte(`["NOTICE", "Error: Invalid EVENT message format"]`))
				continue
			}

			var event models.Event
			if err := json.Unmarshal(rawMessage[1], &event); err != nil {
				errMsg := fmt.Sprintf(`["NOTICE", "Error processing EVENT: %s"]`, err.Error())
				conn.WriteMessage(websocket.TextMessage, []byte(errMsg))
				continue
			}

			// Validate the event
			if !models.ValidateEvent(&event) {
				conn.WriteMessage(websocket.TextMessage, []byte(`["NOTICE", "Error processing message: invalid event: ID or signature verification failed"]`))
				continue
			}

			// If valid, echo it back as OK for now
			conn.WriteMessage(websocket.TextMessage, []byte(`["OK", "`+event.ID+`", true, ""]`))

		case "REQ":
			// Handle subscription requests
			// For now, just acknowledge it
			conn.WriteMessage(websocket.TextMessage, []byte(`["NOTICE", "Subscription received but not implemented"]`))

		case "CLOSE":
			// Handle subscription close
			conn.WriteMessage(websocket.TextMessage, []byte(`["NOTICE", "Subscription closed"]`))

		default:
			// Unknown message type
			errMsg := fmt.Sprintf(`["NOTICE", "Unknown message type: %s"]`, messageType)
			conn.WriteMessage(websocket.TextMessage, []byte(errMsg))
		}
	}

	fmt.Println("Client disconnected")
}

func main() {
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("Hello from COSANOSTRA!"))
	})

	http.HandleFunc("/ws", handleWebSocket)

	fmt.Println("COSANOSTRA starting on :3000.")
	if err := http.ListenAndServe(":3000", nil); err != nil {
		log.Fatal("Error while running ListenAndServe: ", err)
	}
}

