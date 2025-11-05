# LFSocket Usage Guide

WebSocket client for real-time communication with powerful features for production use.

## Features

- **Singleton pattern** - One connection per application
- **Unidirectional messages** - Fire and forget with `emit()`
- **Request/Response** - HTTP-like async requests with `request()`
- **Event listeners** - Subscribe to server events with `on()` and wildcard `"*"` support
- **JSON serialization** - Automatic serialization/deserialization
- **Auto-reconnection** - Exponential backoff with configurable limits
- **Heartbeat/Ping-Pong** - Keep connection alive and detect dead connections
- **Message queue** - Queue messages when offline, auto-flush on reconnect
- **Binary data** - Send binary data with `emitBinary()`
- **Lifecycle callbacks** - `onOpen()`, `onClose()`, `onError()`, `onReconnecting()`
- **Timeout support** - Configurable timeouts for requests

## Quick Start Examples

### Example 1: Connecting to WebSocket

```gdscript
extends Node

func _ready():
	# Simple connection
	LFSocket.connectWS("ws://localhost:3000")
	
	# With connection confirmation
	LFSocket.onOpen(func():
		print("Successfully connected to WebSocket!")
	)
	
	LFSocket.connectWS("ws://localhost:3000")
```

### Example 2: Sending a Message

```gdscript
extends Node

func _ready():
	LFSocket.connectWS("ws://localhost:3000")

func send_player_position():
	# Send a message without waiting for response
	LFSocket.emit("player:move", {
		"x": 150.0,
		"y": 200.0,
		"direction": "north"
	})
	print("Position sent to server")
```

### Example 3: Receiving a Message

```gdscript
extends Node

func _ready():
	# First, set up the event listener
	LFSocket.on("chat:message", _on_chat_received)
	
	# Then connect to the server
	LFSocket.connectWS("ws://localhost:3000")

func _on_chat_received(data):
	# This function is called whenever the server sends a "chat:message" event
	print("Received chat from %s: %s" % [data.username, data.message])
```

### Example 4: Sending a Message and Awaiting Response

```gdscript
extends Node

func _ready():
	LFSocket.connectWS("ws://localhost:3000")

func get_player_stats():
	# Send a request and wait for the server's response
    var response = await LFSocket.request("player:getStats", {
        "playerId": "player_123"
    })
    
    if response:
        print("Player stats received:")
        print("  Health: ", response.health)
        print("  Level: ", response.level)
        print("  Score: ", response.score)
    else:
        print("Failed to get player stats (timeout or error)")
```

### Example 5: Complete Connection with All Features

```gdscript
extends Node

func _ready():
    setup_websocket()

func setup_websocket():
    # Set up lifecycle callbacks
    LFSocket.onOpen(func():
        print("✅ Connected!")
    )
    
    LFSocket.onClose(func():
        print("❌ Disconnected")
    )
    
    # Set up event listeners to receive messages from server
    LFSocket.on("notification", func(data):
        print("📬 Notification: ", data.message)
    )
    
    # Connect to the server
    var options = LFSocket.ConnectionOptions.new()
    options.auto_reconnect = true
    options.reconnect_interval_ms = 2000
    
    LFSocket.connectWS("ws://localhost:3000", options)

func send_message():
    # Send without waiting for response
    LFSocket.emit("chat:send", {
        "message": "Hello, world!"
    })

func request_data():
    # Send and wait for response
    var data = await LFSocket.request("game:getData", {
        "dataType": "leaderboard"
    })
    if data:
        print("Received data: ", data)
```

## Basic Usage

### Connecting to Server

```gdscript
func _ready():
    # Simple connection with default options
    var connected = LFSocket.connectWS("ws://localhost:3000")
    if connected:
        print("Connecting to WebSocket server...")
    else:
        print("Failed to initiate connection")

# With custom options
func connect_with_options():
    var options = LFSocket.ConnectionOptions.new()
    options.auto_reconnect = true
    options.reconnect_interval_ms = 2000
    options.max_reconnect_attempts = 5
    options.heartbeat_interval_ms = 30000
    options.queue_offline_messages = true
    
    LFSocket.connectWS("ws://localhost:3000", options)
```

### Connection Options

All configurable options with their defaults:

```gdscript
var options = LFSocket.ConnectionOptions.new()
options.auto_reconnect = true                    # Enable auto-reconnection
options.reconnect_interval_ms = 1000             # Initial reconnect delay (1s)
options.max_reconnect_interval_ms = 30000        # Max reconnect delay (30s)
options.reconnect_decay = 1.5                    # Exponential backoff multiplier
options.max_reconnect_attempts = 0               # Max attempts (0 = infinite)
options.heartbeat_interval_ms = 30000            # Send ping every 30s
options.heartbeat_timeout_ms = 5000              # Wait 5s for pong before reconnect
options.queue_offline_messages = true            # Queue messages when offline
options.max_queue_size = 100                     # Max queued messages
```

### Lifecycle Callbacks

Monitor connection lifecycle events:

```gdscript
func _ready():
    # Setup callbacks before connecting
    LFSocket.onOpen(func():
        print("✅ Connected to server!")
        # Good place to authenticate or join rooms
    )
    
    LFSocket.onClose(func():
        print("❌ Disconnected from server")
        # Update UI to show offline state
    )
    
    LFSocket.onError(func(error_msg: String):
        print("⚠️ Connection error: ", error_msg)
    )
    
    LFSocket.onReconnecting(func(attempt: int):
        print("🔄 Reconnecting... (attempt %d)" % attempt)
        # Show reconnecting indicator in UI
    )
    
    # Now connect
    LFSocket.connectWS("ws://localhost:3000")
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

# Queue message if offline (will be sent when reconnected)
LFSocket.emit("chat:message", {
    "text": "Hello!"
}, true)  # queue_if_offline = true

# Don't queue if offline (will be dropped)
LFSocket.emit("temp:status", {
	"fps": 60
}, false)  # queue_if_offline = false
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

# Request with custom timeout (10 seconds)
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
	LFSocket.connectWS("ws://localhost:3000")
	
	# Listen to specific events
	LFSocket.on("chat:message", func(data):
		print("New message from %s: %s" % [data.username, data.message])
	)
	
	LFSocket.on("player:joined", func(data):
		print("Player %s joined the game" % data.username)
		_spawn_player(data)
	)
	
	# Wildcard listener - receives ALL events
	LFSocket.on("*", func(event_name: String, data):
		print("Event '%s' received: %s" % [event_name, data])
	)
```

### Binary Data

Send and receive binary data efficiently:

```gdscript
# Send binary data (e.g., audio, images, large datasets)
func send_screenshot():
	var image = get_viewport().get_texture().get_image()
	var png_data = image.save_png_to_buffer()
	LFSocket.emitBinary("screenshot:upload", png_data)

# Receive binary data
func _ready():
	LFSocket.on("file:download", func(data: PackedByteArray):
		print("Received %d bytes" % data.size())
		# Process binary data (save to file, decode, etc.)
		var file = FileAccess.open("user://downloaded.dat", FileAccess.WRITE)
		file.store_buffer(data)
		file.close()
	)
```

### Message Queue Management

Control the offline message queue:

```gdscript
# Check queue size
var queued = LFSocket.getQueueSize()
print("Messages queued: ", queued)

# Clear the queue
LFSocket.clearQueue()

# Queue is automatically flushed when connection reopens
```

### Connection Management

```gdscript
# Check if connected
if LFSocket.isConnected():
	print("Connected!")

# Get detailed status
var status = LFSocket.getStatus()
print("Connected: ", status.connected)
print("URL: ", status.url)
print("State: ", status.state)
print("Pending requests: ", status.pending_requests)
print("Queued messages: ", status.queued_messages)
print("Reconnect attempts: ", status.reconnect_attempts)

# Force reconnection (useful for manual retry)
LFSocket.reconnect()

# Disconnect (allows auto-reconnect by default)
LFSocket.disconnectWS(false)

# Disconnect permanently (no auto-reconnect)
LFSocket.disconnectWS(true)
```

### Removing Event Listeners

```gdscript
var chat_handler = func(data):
	print("Message: ", data.message)

# Add listener
LFSocket.on("chat:message", chat_handler)

# Later, remove it
LFSocket.off("chat:message", chat_handler)

# Remove wildcard listener
var wildcard_handler = func(event, data):
	print(event, data)

LFSocket.on("*", wildcard_handler)
LFSocket.off("*", wildcard_handler)
```

## Complete Example: Multiplayer Game

```gdscript
extends Node

var player_name: String = "Player1"
var is_authenticated: bool = false

func _ready():
	_setup_websocket()

func _setup_websocket():
	# Configure connection options
	var options = LFSocket.ConnectionOptions.new()
	options.auto_reconnect = true
	options.reconnect_interval_ms = 2000
	options.max_reconnect_attempts = 10
	options.heartbeat_interval_ms = 30000
	options.queue_offline_messages = true
	
	# Setup lifecycle callbacks
	LFSocket.onOpen(_on_connection_open)
	LFSocket.onClose(_on_connection_close)
	LFSocket.onError(_on_connection_error)
	LFSocket.onReconnecting(_on_reconnecting)
	
	# Setup event listeners
	LFSocket.on("chat:message", _on_chat_message)
	LFSocket.on("player:joined", _on_player_joined)
	LFSocket.on("player:left", _on_player_left)
	LFSocket.on("game:state", _on_game_state_update)
	
	# Wildcard listener for debugging
	LFSocket.on("*", func(event, data):
		print("[DEBUG] Event: %s, Data: %s" % [event, data])
	)
	
	# Connect to server
	var connected = LFSocket.connectWS("ws://localhost:3000", options)
	if !connected:
		push_error("Failed to initiate connection")

func _on_connection_open():
	print("✅ Connected to game server!")
	_authenticate()

func _on_connection_close():
	print("❌ Disconnected from game server")
	is_authenticated = false
	# Update UI to show offline state
	$UI/StatusLabel.text = "Offline"

func _on_connection_error(error: String):
	print("⚠️ Connection error: ", error)
	$UI/ErrorLabel.text = "Error: " + error

func _on_reconnecting(attempt: int):
	print("🔄 Reconnecting... (attempt %d)" % attempt)
	$UI/StatusLabel.text = "Reconnecting... (%d)" % attempt

func _authenticate():
	var auth_response = await LFSocket.request("auth:login", {
		"username": player_name,
		"token": _get_auth_token()
	}, 10000)
	
	if auth_response && auth_response.get("success"):
		print("Authenticated successfully!")
		is_authenticated = true
		$UI/StatusLabel.text = "Online"
		_join_game()
	else:
		push_error("Authentication failed")
		$UI/StatusLabel.text = "Auth failed"

func _join_game():
	var join_response = await LFSocket.request("game:join", {
		"gameId": "quick_match",
		"playerData": {
			"name": player_name,
			"level": 10
		}
	})
	
	if join_response:
		print("Joined game: ", join_response.gameId)
		$UI/RoomLabel.text = "Room: " + join_response.gameId

func _on_chat_message(data):
	print("[%s]: %s" % [data.username, data.message])
	$UI/ChatBox.add_message(data.username, data.message)

func _on_player_joined(data):
	print("Player joined: ", data.username)
	$UI/PlayerList.add_player(data)
	_spawn_player(data)

func _on_player_left(data):
	print("Player left: ", data.username)
	$UI/PlayerList.remove_player(data.playerId)
	_despawn_player(data.playerId)

func _on_game_state_update(data):
	# Update game state based on server data
	for player in data.players:
		_update_player_position(player.id, player.position)

func send_chat_message(message: String):
	if !is_authenticated:
		print("Cannot send message: not authenticated")
		return
	
	LFSocket.emit("chat:send", {
		"message": message
	})

func send_player_movement(position: Vector2):
	# Fire and forget, don't queue if offline
    LFSocket.emit("player:move", {
        "x": position.x,
        "y": position.y
    }, false)

func request_player_stats(player_id: String):
    var stats = await LFSocket.request("player:getStats", {
        "playerId": player_id
    }, 5000)
    
    if stats:
        _display_stats(stats)
    else:
        print("Failed to get player stats")

func _get_auth_token() -> String:
    # In production, get from secure storage
    return "your_auth_token_here"

func _spawn_player(player_data):
    # Implement player spawning
    pass

func _despawn_player(player_id: String):
    # Implement player despawning
    pass

func _update_player_position(player_id: String, position: Dictionary):
    # Implement position update
    pass

func _display_stats(stats: Dictionary):
    # Display player stats in UI
    pass

func _exit_tree():
    LFSocket.disconnectWS(true)
```

## Auto-Reconnection

LFSocket automatically handles reconnection with exponential backoff:

1. **Initial attempt**: Reconnects after `reconnect_interval_ms` (default: 1000ms)
2. **Backoff**: Each subsequent attempt multiplies delay by `reconnect_decay` (default: 1.5x)
3. **Max delay**: Caps at `max_reconnect_interval_ms` (default: 30000ms)
4. **Max attempts**: Stops after `max_reconnect_attempts` tries (0 = infinite)

Example timeline with defaults:
- Attempt 1: 1s delay
- Attempt 2: 1.5s delay
- Attempt 3: 2.25s delay
- Attempt 4: 3.375s delay
- ...
- Capped at 30s delay

## Heartbeat/Ping-Pong

Automatic heartbeat keeps the connection alive and detects dead connections:

1. Client sends "ping" every `heartbeat_interval_ms` (default: 30s)
2. Server should respond with "pong"
3. If no "pong" received within `heartbeat_timeout_ms` (default: 5s), reconnects

Your server should handle ping/pong:

```typescript
// NestJS example
@SubscribeMessage('message')
handleMessage(@MessageBody() data: string) {
  if (data === 'ping') {
	return 'pong';
  }
  // Handle other messages...
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

**Ping:**
```
"ping"
```

**Binary (Event Prefixed):**
```
[4 bytes: event_name_length][event_name_bytes][binary_data]
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

**Pong:**
```
"pong"
```

## NestJS Server Integration

Example NestJS WebSocket Gateway:

```typescript
import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';

@WebSocketGateway()
export class GameGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  handleConnection(client: Socket) {
    console.log(`Client connected: ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    console.log(`Client disconnected: ${client.id}`);
  }

  // Handle unidirectional messages (emit)
  @SubscribeMessage('player:move')
  handleMove(@MessageBody() data: any, @ConnectedSocket() client: Socket) {
	console.log('Player moved:', data);
    // Broadcast to other players
	client.broadcast.emit('player:moved', { clientId: client.id, ...data });
  }

  // Handle request/response
  @SubscribeMessage('player:stats')
  async handleStatsRequest(@MessageBody() data: any) {
    const stats = await this.getPlayerStats(data.playerId);
    return {
	  type: 'response',
      id: data.id, // Echo back the request ID
      data: stats,
    };
  }

  // Handle ping/pong for heartbeat
  @SubscribeMessage('message')
  handleMessage(@MessageBody() data: string) {
	if (data === 'ping') {
	  return 'pong';
    }
  }

  // Broadcast events to specific clients or everyone
  broadcastChatMessage(message: string, username: string) {
	this.server.emit('chat:message', {
	  event: 'chat:message',
      data: { username, message },
    });
  }

  sendToClient(clientId: string, event: string, data: any) {
    this.server.to(clientId).emit(event, {
      event,
      data,
    });
  }

  private async getPlayerStats(playerId: string) {
    // Fetch from database
    return { health: 100, level: 5, score: 1250 };
  }
}
```

## Best Practices

1. **Setup callbacks before connecting** - Register `onOpen()`, `onClose()`, `onError()` before calling `connectWS()`
2. **Use appropriate timeouts** - Set realistic timeouts for requests based on expected response time
3. **Handle disconnections gracefully** - Use lifecycle callbacks to update UI and handle offline state
4. **Choose emit vs request wisely** - Use `emit()` for fire-and-forget, `request()` when you need confirmation
5. **Queue offline messages strategically** - Not all messages need queuing (e.g., real-time position updates)
6. **Use meaningful event names** - Follow a namespace pattern (e.g., `entity:action`)
7. **Validate response data** - Always check if response is not null and has expected structure
8. **Clean up listeners** - Remove listeners in `_exit_tree()` or when no longer needed
9. **Handle reconnection in UI** - Show connection status and reconnecting indicators
10. **Use wildcard listeners sparingly** - `"*"` listeners receive all events, use for debugging only

## Error Handling

```gdscript
# Always check connection before critical operations
if !LFSocket.isConnected():
    push_error("Not connected to server")
    _show_offline_message()
    return

# Handle timeout in requests
var response = await LFSocket.request("slow:operation", {}, 10000)
if response == null:
    print("Request timed out")
    _handle_timeout()
    return

# Monitor connection errors
LFSocket.onError(func(error_msg: String):
    push_error("WebSocket error: ", error_msg)
    _notify_user_of_error(error_msg)
)

# Handle reconnection attempts
var max_retries = 5
LFSocket.onReconnecting(func(attempt: int):
    if attempt > max_retries:
        _show_connection_failed_dialog()
)
```

## Performance Tips

1. **Batch updates** - Instead of sending many small messages, batch them when possible
2. **Use binary for large data** - Images, audio, large arrays are better sent as binary
3. **Don't queue real-time data** - Position updates, FPS counters shouldn't be queued
4. **Adjust heartbeat interval** - Longer intervals (60s) for stable connections, shorter (15s) for unreliable networks
5. **Limit wildcard listeners** - They receive every event, can impact performance
6. **Clear queue if too old** - Old queued messages might not be relevant after reconnect

## Troubleshooting

### Connection keeps reconnecting

- Check server is running and accessible
- Verify URL is correct (ws:// or wss://)
- Check firewall/network restrictions
- Increase `heartbeat_timeout_ms` if network is slow

### Messages not received

- Verify server is sending correct message format
- Check event names match exactly (case-sensitive)
- Ensure listener is registered before messages arrive
- Check for JSON parsing errors in console

### Request always times out

- Increase timeout parameter in `request()` call
- Verify server is returning response with correct ID
- Check server response format matches protocol
- Ensure connection is stable

### Queue keeps filling up

- Check connection is established
- Reduce `max_queue_size` to prevent memory issues
- Clear queue periodically: `LFSocket.clearQueue()`
- Don't queue unnecessary messages

## API Reference

### Static Methods

- `connectWS(url: String, options: ConnectionOptions = null) -> bool`
- `disconnectWS(disable_reconnect: bool = true) -> void`
- `isConnected() -> bool`
- `emit(event: String, data: Variant = {}, queue_if_offline: bool = true) -> void`
- `request(event: String, data: Variant = {}, timeout_ms: int = 5000) -> Variant`
- `on(event: String, callback: Callable) -> void`
- `off(event: String, callback: Callable) -> void`
- `getStatus() -> Dictionary`
- `onOpen(callback: Callable) -> void`
- `onClose(callback: Callable) -> void`
- `onError(callback: Callable) -> void`
- `onReconnecting(callback: Callable) -> void`
- `emitBinary(event: String, data: PackedByteArray) -> void`
- `getQueueSize() -> int`
- `clearQueue() -> void`
- `reconnect() -> void`

### ConnectionOptions Properties

- `auto_reconnect: bool = true`
- `reconnect_interval_ms: int = 1000`
- `max_reconnect_interval_ms: int = 30000`
- `reconnect_decay: float = 1.5`
- `max_reconnect_attempts: int = 0`
- `heartbeat_interval_ms: int = 30000`
- `heartbeat_timeout_ms: int = 5000`
- `queue_offline_messages: bool = true`
- `max_queue_size: int = 100`

## License

This utility is part of the LF Utils library.
