package main

import (
	"fmt"
	"log"
	"net/http"

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
		messageType, message, err := conn.ReadMessage()
		if err != nil {
			log.Println("Message read error: ", err)
			break
		}
		fmt.Printf("Received: %s\n", message)

		writeErr := conn.WriteMessage(messageType, message)

		if writeErr != nil {
			log.Println("Error while writing message back to client: ", writeErr)
			break
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
