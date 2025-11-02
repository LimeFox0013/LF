class_name LFSocket;
extends Node;

## WebSocket client for communicating with NestJS backend
## Supports both unidirectional messages and request/response patterns
## All communication is JSON-based

static var _instance: LFSocketInstance;

## Connect to WebSocket server
## @param url: WebSocket URL (e.g., "ws://localhost:3000")
## @return: true if connection initiated successfully
static func connectWS(url: String) -> bool:
	if _instance && _instance.isConnected():
		push_warning("LFSocket: Already connected. Disconnect first.");
		return false;
	
	_instance = LFSocketInstance.new();
	return _instance.connect_to_server(url);

## Disconnect from WebSocket server
static func disconnectWS() -> void:
	if _instance:
		_instance.disconnect_from_server();
		_instance = null;

## Check if connected
static func isConnected() -> bool:
	return _instance != null && _instance.isConnected();

## Send unidirectional message (fire and forget)
## @param event: Event name
## @param data: Data to send (will be converted to JSON)
static func emit(event: String, data: Variant = {}) -> void:
	if !_instance:
		push_error("LFSocket: Not connected. Call connect() first.");
		return;
	_instance.emit_message(event, data);

## Send request and wait for response (HTTP-like)
## @param event: Event name
## @param data: Data to send (will be converted to JSON)
## @param timeout_ms: Timeout in milliseconds (0 = no timeout)
## @return: Response data or null on error/timeout
static func request(event: String, data: Variant = {}, timeout_ms: int = 5000) -> Variant:
	if !_instance:
		push_error("LFSocket: Not connected. Call connect() first.");
		return null;
	return await _instance.request_message(event, data, timeout_ms);

## Listen to server events
## @param event: Event name to listen for
## @param callback: Callable to execute when event received
static func on(event: String, callback: Callable) -> void:
	if !_instance:
		push_error("LFSocket: Not connected. Call connect() first.");
		return;
	_instance.on_event(event, callback);

## Remove event listener
## @param event: Event name
## @param callback: Callable to remove
static func off(event: String, callback: Callable) -> void:
	if _instance:
		_instance.off_event(event, callback);

## Get connection status
static func getStatus() -> Dictionary:
	if !_instance:
		return { "connected": false, "url": "" };
	return _instance.getStatus();


# ============================================================================
# Internal WebSocket Instance
# ============================================================================

class LFSocketInstance extends RefCounted:
	var _socket: WebSocketPeer;
	var _url: String;
	var _connected: bool = false;
	var _listeners: Dictionary = {}; # event -> Array[Callable]
	var _pending_requests: Dictionary = {}; # request_id -> { callback, timeout }
	var _request_counter: int = 0;
	
	signal connected;
	signal disconnected;
	signal error(message: String);
	
	func _init() -> void:
		_socket = WebSocketPeer.new();
	
	func connect_to_server(url: String) -> bool:
		_url = url;
		var err := _socket.connect_to_url(url);
		if err != OK:
			push_error("LFSocket: Failed to connect to %s (error %d)" % [url, err]);
			return false;
		
		# Start polling in background
		_start_polling();
		return true;
	
	func disconnect_from_server() -> void:
		if _socket:
			_socket.close();
		_connected = false;
		disconnected.emit();
	
	func isConnected() -> bool:
		return _connected;
	
	func emit_message(event: String, data: Variant) -> void:
		var message := {
			"type": "emit",
			"event": event,
			"data": data
		};
		_send_json(message);
	
	func request_message(event: String, data: Variant, timeout_ms: int) -> Variant:
		_request_counter += 1;
		var request_id := "req_%d_%d" % [Time.get_ticks_msec(), _request_counter];
		
		var message := {
			"type": "request",
			"id": request_id,
			"event": event,
			"data": data
		};
		
		# Create promise for response
		var response_received := false;
		var response_data: Variant = null;
		
		_pending_requests[request_id] = {
			"callback": func(data: Variant) -> void:
				response_data = data;
				response_received = true,
			"created_at": Time.get_ticks_msec()
		};
		
		_send_json(message);
		
		# Wait for response with timeout
		var start_time := Time.get_ticks_msec();
		while !response_received:
			if timeout_ms > 0 && (Time.get_ticks_msec() - start_time) > timeout_ms:
				_pending_requests.erase(request_id);
				push_warning("LFSocket: Request timeout for event '%s'" % event);
				return null;
			await LFAwait.nextTick;
		
		_pending_requests.erase(request_id);
		return response_data;
	
	func on_event(event: String, callback: Callable) -> void:
		if !_listeners.has(event):
			_listeners[event] = [];
		_listeners[event].append(callback);
	
	func off_event(event: String, callback: Callable) -> void:
		if _listeners.has(event):
			_listeners[event].erase(callback);
	
	func getStatus() -> Dictionary:
		return {
			"connected": _connected,
			"url": _url,
			"state": _socket.get_ready_state() if _socket else WebSocketPeer.STATE_CLOSED,
			"pending_requests": _pending_requests.size()
		};
	
	func _send_json(data: Dictionary) -> void:
		if !_socket:
			push_error("LFSocket: Socket not initialized");
			return;
		
		var json_str := JSON.stringify(data);
		var err := _socket.send_text(json_str);
		if err != OK:
			push_error("LFSocket: Failed to send message (error %d)" % err);
	
	func _start_polling() -> void:
		var tree := Engine.get_main_loop() as SceneTree;
		if !tree:
			push_error("LFSocket: SceneTree not available");
			return;
		
		# Poll WebSocket in background
		var poll_task := func() -> void:
			while _socket:
				_socket.poll();
				var state := _socket.get_ready_state();
				
				# Handle connection state
				if state == WebSocketPeer.STATE_OPEN && !_connected:
					_connected = true;
					connected.emit();
				elif state == WebSocketPeer.STATE_CLOSED && _connected:
					_connected = false;
					disconnected.emit();
					break;
				
				# Process incoming messages
				while _socket.get_available_packet_count() > 0:
					var packet := _socket.get_packet();
					var json_str := packet.get_string_from_utf8();
					_handle_message(json_str);
				
				await tree.process_frame;
		
		poll_task.call();
	
	func _handle_message(json_str: String) -> void:
		var json := JSON.new();
		var parse_err := json.parse(json_str);
		if parse_err != OK:
			push_error("LFSocket: Failed to parse JSON: %s" % json_str);
			return;
		
		var message: Dictionary = json.data;
		
		# Handle response to request
		if message.has("type") && message["type"] == "response":
			var request_id: String = message.get("id", "");
			if _pending_requests.has(request_id):
				var pending = _pending_requests[request_id];
				pending["callback"].call(message.get("data"));
			return;
		
		# Handle server event
		if message.has("event"):
			var event: String = message["event"];
			var data: Variant = message.get("data", {});
			
			if _listeners.has(event):
				for callback in _listeners[event]:
					callback.call(data);
