package main

import (
	"encoding/json"
	"log"
	"os"
    "fmt"
    "sync"

	maelstrom "github.com/jepsen-io/maelstrom/demo/go"
)

var mu sync.Mutex

func main() {
	n := maelstrom.NewNode()
    var counter = 0

	// Register a handler for the "echo" message that responds with an "echo_ok".
	n.Handle("echo", func(msg maelstrom.Message) error {
		// Unmarshal the message body as an loosely-typed map.
		var body map[string]any
		if err := json.Unmarshal(msg.Body, &body); err != nil {
			return err
		}

		// Update the message type.
		body["type"] = "echo_ok"

		// Echo the original message back with the updated message type.
		return n.Reply(msg, body)
	})

    // Register a handler for the "generate" message that responds with an "generate_ok" and a unique ID.
	n.Handle("generate", func(msg maelstrom.Message) error {
		// Unmarshal the message body as an loosely-typed map.
		var body map[string]any
		if err := json.Unmarshal(msg.Body, &body); err != nil {
			return err
		}
		
		// Get current counter value and increment it.
		body["id"] = generateID(counter, n.ID())
        counter++

		// Update the message type.
		body["type"] = "generate_ok"

		return n.Reply(msg, body)
	})

	// Execute the node's message loop. This will run until STDIN is closed.
	if err := n.Run(); err != nil {
		log.Printf("ERROR: %s", err)
		os.Exit(1)
	}
}

func generateID(num int, nodeID string) string {
    mu.Lock()
    defer mu.Unlock()
    id := fmt.Sprintf("%d-%s", num, nodeID) 
    return id
}
