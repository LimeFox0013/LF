# LFSocket Usage Guide

WebSocket client for real-time communication with NestJS backend.

## Features

- **Singleton pattern** - One connection per application
- **Unidirectional messages** - Fire and forget with `emit()`
- **Request/Response** - HTTP-like async requests with `request()`
- **Event listeners** - Subscribe to server events with `on()`
- **JSON serialization** - Automatic serialization/deserialization
- **Connection management** - Automatic reconnection handling
- **Timeout support** - Configurable timeouts for requests

## Basic Usage

### Connecting to Server

```gdscript
func _ready():
    # Connect to local NestJS server
    var connected = LFSocket.connect("ws://localhost:3000")
    if connected:
        print("Connecting to WebSocket server...")
    else:
        print("Failed to initiate connection")
```

### Unidirectional Messages (emit)

Send messages without waiting for a response:

```gdscript
# Send a simple event
LFSocket.emit("player:move", {
    "x": 100,
    "y": 200,
    "speed": 5.0
})

# Send without data
LFSocket.emit("game:start")

# Send complex data
LFSocket.emit("inventory:update", {
    "items": [
        { "id": 1, "name": "Sword", "quantity": 1 },
        { "id": 2, "name": "Potion", "quantity": 5 }
    ],
    "gold": 1500
})
```

### Request/Response (HTTP-like)

Send requests and await responses:

```gdscript
# Basic request with default timeout (5000ms)
var response = await LFSocket.request("player:stats", { "playerId": "123" })
if response:
    print("Player stats: ", response)
else:
    print("Request timed out or failed")

# Request with custom timeout
var leaderboard = await LFSocket.request("game:leaderboard", {}, 10000)
print("Top players: ", leaderboard)

# Handle response data
var saveResult = await LFSocket.request("game:save", {
    "slot": 1,
    "checkpoint": "level_3_boss"
})
if saveResult && saveResult.get("success"):
    print("Game saved successfully!")
```

### Listening to Server Events

Subscribe to events pushed from the server:

```gdscript
func _ready():
    LFSocket.connect("ws://localhost:3000")
    
    # Listen to chat messages
    LFSocket.on("chat:message", func(data):
        print("New message from %s: %s" % [data.username, data.message])
    )
    
    # Listen to player joins
    LFSocket.on("player:joined", func(data):
        print("Player %s joined the game" % data.username)
        _spawn_player(data)
    )
    
    # Listen to game state updates
    LFSocket.on("game:state", func(data):
        _update_game_state(data)
    )
```

### Removing Event Listeners

```gdscript
var chat_handler = func(data):
    print("Message: ", data.message)

# Add listener
LFSocket.on("chat:message", chat_handler)

# Later, remove it
LFSocket.off("chat:message", chat_handler)
```

### Checking Connection Status

```gdscript
# Simple check
if LFSocket.isConnected():
    print("Connected!")

# Detailed status
var status = LFSocket.getStatus()
print("Connected: ", status.connected)
print("URL: ", status.url)
print("State: ", status.state)
print("Pending requests: ", status.pending_requests)
```

### Disconnecting

```gdscript
func _exit_tree():
    LFSocket.disconnect()
```

## Complete Example

```gdscript
extends Node

func _ready():
    _setup_websocket()

func _setup_websocket():
    # Connect to server
    var connected = LFSocket.connect("ws://localhost:3000")
    if !connected:
        push_error("Failed to connect to WebSocket server")
        return
    
    # Setup event listeners
    LFSocket.on("chat:message", _on_chat_message)
    LFSocket.on("player:joined", _on_player_joined)
    LFSocket.on("player:left", _on_player_left)
    
    # Wait a bit for connection to establish
    await get_tree().create_timer(1.0).timeout
    
    # Authenticate
    var auth_response = await LFSocket.request("auth:login", {
        "username": "Player1",
        "token": "abc123"
    })
    
    if auth_response && auth_response.get("success"):
        print("Authenticated successfully!")
        _join_game()
    else:
        print("Authentication failed")

func _join_game():
    # Request to join game
    var join_response = await LFSocket.request("game:join", {
        "gameId": "quick_match"
    })
    
    if join_response:
        print("Joined game: ", join_response.gameId)

func _on_chat_message(data):
    print("[%s]: %s" % [data.username, data.message])

func _on_player_joined(data):
    print("Player joined: ", data.username)

func _on_player_left(data):
    print("Player left: ", data.username)

func send_chat_message(message: String):
    LFSocket.emit("chat:send", {
        "message": message
    })

func _exit_tree():
    LFSocket.disconnect()
```

## NestJS Server Integration

Your NestJS WebSocket Gateway should handle the message formats:

```typescript
// Example NestJS Gateway
@WebSocketGateway()
export class GameGateway {
  @SubscribeMessage('player:move')
  handleMove(@MessageBody() data: any) {
    // Unidirectional - no response needed
    console.log('Player moved:', data);
  }

  @SubscribeMessage('player:stats')
  async handleStatsRequest(@MessageBody() data: any) {
    // Request/Response - must respond with same ID
    const stats = await this.getPlayerStats(data.playerId);
    return {
      type: 'response',
      id: data.id, // Echo back the request ID
      data: stats
    };
  }

  // Push events to clients
  broadcastMessage(event: string, data: any) {
    this.server.emit('chat:message', {
      event: 'chat:message',
      data: data
    });
  }
}
```

## Message Protocol

### Client to Server

**Emit (Unidirectional):**
```json
{
  "type": "emit",
  "event": "player:move",
  "data": { "x": 100, "y": 200 }
}
```

**Request (Requires Response):**
```json
{
  "type": "request",
  "id": "req_1234567890_1",
  "event": "player:stats",
  "data": { "playerId": "123" }
}
```

### Server to Client

**Response:**
```json
{
  "type": "response",
  "id": "req_1234567890_1",
  "data": { "health": 100, "level": 5 }
}
```

**Server Event:**
```json
{
  "event": "chat:message",
  "data": { "username": "Player1", "message": "Hello!" }
}
```

## Best Practices

1. **Always check connection** before sending messages
2. **Use appropriate timeouts** for requests based on expected response time
3. **Handle connection loss** gracefully with reconnection logic
4. **Clean up listeners** in `_exit_tree()` or when no longer needed
5. **Use meaningful event names** following a namespace pattern (e.g., `entity:action`)
6. **Validate response data** before using it
7. **Keep message payloads small** for better performance
8. **Use emit for fire-and-forget**, request for when you need confirmation

## Error Handling

```gdscript
# Check if connected before operations
if !LFSocket.isConnected():
    push_error("Not connected to server")
    return

# Handle timeout in requests
var response = await LFSocket.request("slow:operation", {}, 10000)
if response == null:
    print("Request timed out")
    # Handle timeout gracefully

# Monitor
