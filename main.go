package main

import (
	"fmt"
	"log"
	"net/http"

	"github.com/gorilla/websocket"

	"cosanostra/pkg/relay"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true // Allow connections from any origin for now
	},
}

func main() {
	nostrRelay := relay.NewRelay()
	go nostrRelay.Run()

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("Hello from COSANOSTRA!"))
	})

	http.HandleFunc("/ws", func(w http.ResponseWriter, r *http.Request) {
		conn, err := upgrader.Upgrade(w, r, nil)
		if err != nil {
			log.Println("Connection upgrade error: ", err)
			return
		}

		fmt.Println("New client connected!")
		nostrRelay.HandleConnection(conn)
	})

	port := ":3000"
	fmt.Println("COSANOSTRA starting on", port)
	if err := http.ListenAndServe(port, nil); err != nil {
		log.Fatal("Error while running ListenAndServe: ", err)
	}
}

