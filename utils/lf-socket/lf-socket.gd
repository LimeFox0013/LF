class_name LFSocket;
extends RefCounted;


var _socket: WebSocketPeer;
var _url: String;
var _uid := LFUuid.gen('socket-instance');
var _logger := LFLogger.new(['[LFSocket] (%s):' % [_uid]]);
var _connected: bool = false;
var _options: LFSocketOptions;
var _listeners: Dictionary = {}; # event -> Array[Callable]
var _wildcard_listeners: Array[Callable] = [];  # Listeners for all events
var _pending_requests: Dictionary = {}; # request_id -> { callback, timeout }
var _request_counter: int = 0;
var _message_queue: Array = [];  # Queue for offline messages
var _should_reconnect: bool = true;
var _reconnect_attempts: int = 0;
var _current_reconnect_interval: int = 0;
var _last_heartbeat_time: int = 0;
var _waiting_for_pong: bool = false;
	
# Lifecycle callbacks
var _on_open_callbacks: Array[Callable] = [];
var _on_close_callbacks: Array[Callable] = [];
var _on_error_callbacks: Array[Callable] = [];
var _on_reconnecting_callbacks: Array[Callable] = [];

signal connected;
signal disconnected;
signal error(message: String);
signal reconnecting(attempt: int);

func _init() -> void:
	_socket = WebSocketPeer.new();

func connect_to_server(url: String, options := LFSocketOptions.new()) -> bool:
	_logger.log('Initializing connection to: %s' % url)
	_url = url;
	_options = options;
	_current_reconnect_interval = options.reconnect_interval_ms;
	_logger.log('Configuration - heartbeat: %dms, max_queue: %d, auto_reconnect: %s' % [options.heartbeat_interval_ms, options.max_queue_size, options.auto_reconnect])
	return _attempt_connection();

func _attempt_connection() -> bool:
	_logger.log('Attempting connection to: %s' % _url)
	_logger.log('Socket state before connect: %d' % _socket.get_ready_state())
	
	var err := _socket.connect_to_url(_url);
	
	if err != OK:
		_logger.error('Failed to initiate connection to %s (error code: %d)' % [_url, err]);
		_logger.log('Error codes: OK=0, FAILED=1, ERR_INVALID_PARAMETER=30')
		_trigger_error('Connection failed: error %d' % err);
		_schedule_reconnect();
		return false;
	
	_logger.log('Connection initiated successfully, socket state: %d' % _socket.get_ready_state())
	_logger.log('State codes: CONNECTING=0, OPEN=1, CLOSING=2, CLOSED=3')
	
	# Start polling in background
	_start_polling();
	return true;

func disconnect_from_server(disable_reconnect: bool = true) -> void:
	_logger.log('Disconnecting from server, disable_reconnect: %s' % disable_reconnect)
	_should_reconnect = !disable_reconnect;
	if _socket:
		_logger.log('Closing socket, current state: %d' % _socket.get_ready_state())
		_socket.close();
	_connected = false;
	_trigger_close();

func isConnected() -> bool:
	return _connected;

func sendMessage(message: Variant, queue_if_offline: bool = true) -> void:
	_logger.log('sendMessage():', message, 'connected: %s' % [_connected]);
	
	if !_connected && queue_if_offline && _options.queue_offline_messages:
		_logger.log('Not connected, queueing message...')
		_queue_message(message);
	else:
		_send_json(message);


func emit_binary(event: String, data: PackedByteArray) -> void:
	_logger.log('emit_binary() called for event: %s, data size: %d bytes' % [event, data.size()])
	if !_socket || !_connected:
		push_warning('[LFSocket]: Cannot send binary data when not connected');
		return;
	
	# Prefix with event name (simple protocol: first 4 bytes = event name length, then event name, then data)
	var event_bytes := event.to_utf8_buffer();
	var event_length := event_bytes.size();
	var header := PackedByteArray();
	header.append(event_length & 0xFF);
	header.append((event_length >> 8) & 0xFF);
	header.append((event_length >> 16) & 0xFF);
	header.append((event_length >> 24) & 0xFF);
	
	var full_data := PackedByteArray();
	full_data.append_array(header);
	full_data.append_array(event_bytes);
	full_data.append_array(data);
	
	var err := _socket.send(full_data);
	if err != OK:
		_logger.error('Failed to send binary data (error %d)' % err);
	else:
		_logger.log('Binary data sent successfully, total size: %d bytes' % full_data.size())

func request_message(payload, timeout_ms := 5000) -> Variant:
	_request_counter += 1;
	var request_id := 'req_%d_%d' % [Time.get_ticks_msec(), _request_counter];
	
	_logger.log('request_message() -', payload, 'id: %s, timeout: %dms' % [request_id, timeout_ms]);
	
	var message := {
		'type': 'request',
		'id': request_id,
		'payload': payload,
	};
	
	# Create promise for response
	var response_received := false;
	var response_data: Variant = null;
	
	_pending_requests[request_id] = {
		'callback': func(data_response: Variant) -> void:
			response_data = data_response;
			response_received = true,
		'created_at': Time.get_ticks_msec()
	};
	
	_send_json(message);
	
	# Wait for response with timeout
	var start_time := Time.get_ticks_msec();
	while !response_received:
		if timeout_ms > 0 && (Time.get_ticks_msec() - start_time) > timeout_ms:
			_pending_requests.erase(request_id);
			push_warning('[LFSocket]: Request timeout for (id: %s)' % [request_id]);
			return null;
		await LFAwait.nextTick;
	
	_logger.log('Received response for request id: %s' % request_id)
	_pending_requests.erase(request_id);
	return response_data;

func on_event(event: String, callback: Callable) -> void:
	if event == '*':
		_wildcard_listeners.append(callback);
		return;
	
	if !_listeners.has(event):
		_listeners[event] = [];
	_listeners[event].append(callback);

func off_event(event: String, callback: Callable) -> void:
	if event == '*':
		_wildcard_listeners.erase(callback);
		return;
	
	if _listeners.has(event):
		_listeners[event].erase(callback);

func on_open(callback: Callable) -> void:
	_on_open_callbacks.append(callback);

func on_close(callback: Callable) -> void:
	_on_close_callbacks.append(callback);

func on_error(callback: Callable) -> void:
	_on_error_callbacks.append(callback);

func on_reconnecting(callback: Callable) -> void:
	_on_reconnecting_callbacks.append(callback);

func get_queue_size() -> int:
	return _message_queue.size();

func clear_queue() -> void:
	_message_queue.clear();

func force_reconnect() -> void:
	if _connected:
		disconnect_from_server(false);
	_reconnect_attempts = 0;
	_current_reconnect_interval = _options.reconnect_interval_ms;
	_attempt_connection();

func getStatus() -> Dictionary:
	return {
		'connected': _connected,
		'url': _url,
		'state': _socket.get_ready_state() if _socket else WebSocketPeer.STATE_CLOSED,
		'pending_requests': _pending_requests.size(),
		'queued_messages': _message_queue.size(),
		'reconnect_attempts': _reconnect_attempts,
		'auto_reconnect': _options.auto_reconnect if _options else false
	};

func health() -> Dictionary:
	return {
		'status': 200,
		'state': 'ok'
	};

func _send_json(data: Dictionary) -> void:
	if !_socket:
		_logger.error('Socket not initialized');
		return;
	
	if !_connected:
		push_warning('[LFSocket]: Cannot send message when not connected, socket state: %d' % _socket.get_ready_state());
		return;
	
	var json_str := JSON.stringify(data);
	_logger.log('Sending JSON message, type: %s, size: %d bytes' % [data.get('type', 'unknown'), json_str.length()])
	var err := _socket.send_text(json_str);
	if err != OK:
		_logger.error('Failed to send message (error %d)' % err);
	else:
		_logger.log('Message sent successfully')

func _queue_message(message: Dictionary) -> void:
	if _message_queue.size() >= _options.max_queue_size:
		# Remove oldest message if queue is full
		_message_queue.pop_front();
		push_warning('[LFSocket]: Message queue full (%d messages), removed oldest message' % _options.max_queue_size);
	_message_queue.append(message);
	_logger.log('Message queued, queue size: %d/%d' % [_message_queue.size(), _options.max_queue_size])

func _flush_queue() -> void:
	if _message_queue.is_empty():
		_logger.log('Queue is empty, nothing to flush')
		return;
	
	_logger.log('Flushing %d queued messages' % _message_queue.size());
	for message in _message_queue:
		_send_json(message);
	_message_queue.clear();
	_logger.log('Queue flushed successfully')

func _start_polling() -> void:
	var tree := Engine.get_main_loop() as SceneTree;
	if !tree:
		_logger.error('SceneTree not available');
		return;
	
	_logger.log('Starting polling loop')
	
	# Poll WebSocket in background
	var poll_task := func() -> void:
		var last_state := -1
		while _socket:
			_socket.poll();
			var state := _socket.get_ready_state();
			
			# Log state changes
			if state != last_state:
				var state_names := {
					WebSocketPeer.STATE_CONNECTING: 'CONNECTING',
					WebSocketPeer.STATE_OPEN: 'OPEN',
					WebSocketPeer.STATE_CLOSING: 'CLOSING',
					WebSocketPeer.STATE_CLOSED: 'CLOSED'
				}
				_logger.log('State changed: %s -> %s' % [state_names.get(last_state, 'UNKNOWN'), state_names.get(state, 'UNKNOWN')])
				last_state = state
			
			# Handle connection state
			if state == WebSocketPeer.STATE_OPEN && !_connected:
				_logger.log('Connection established successfully!')
				_connected = true;
				_reconnect_attempts = 0;
				_current_reconnect_interval = _options.reconnect_interval_ms;
				connected.emit();
				_trigger_open();
				_flush_queue();
				_start_heartbeat();
			elif state == WebSocketPeer.STATE_CLOSED && _connected:
				_logger.log('Connection closed')
				_connected = false;
				disconnected.emit();
				_trigger_close();
				if _should_reconnect:
					_schedule_reconnect();
				break;
			elif state == WebSocketPeer.STATE_CLOSED && !_connected && last_state == WebSocketPeer.STATE_CONNECTING:
				_logger.log('Connection failed - never reached OPEN state')
				_logger.log('Close code: %d, reason: %s' % [_socket.get_close_code(), _socket.get_close_reason()])
				if _should_reconnect:
					_schedule_reconnect();
				break;
			
			# Process incoming messages
			var packet_count := _socket.get_available_packet_count()
			if packet_count > 0:
				_logger.log('Processing %d incoming packet(s)' % packet_count)
			
			while _socket.get_available_packet_count() > 0:
				var packet := _socket.get_packet();
				var is_text := _socket.was_string_packet();
				if is_text:
					var json_str := packet.get_string_from_utf8();
					_logger.log('Received text message: %s' % json_str)
					_handle_message(json_str);
				else:
					_logger.log('Received binary message, size: %d bytes' % packet.size())
					_handle_binary_message(packet);
			
			# Check heartbeat
			if _connected && _options.heartbeat_interval_ms > 0:
				_check_heartbeat();
			
			await tree.process_frame;
	
	poll_task.call();

func _handle_message(json_str: String) -> void:
	var json := JSON.new();
	var parse_err := json.parse(json_str);
	if parse_err != OK:
		_logger.error('Failed to parse JSON: %s' % json_str);
		return;
	
	var message: Dictionary = json.data;
	_logger.log('Parsed message', message);
	
	if message.has('type'):
		if message.type == 'pong':
			_logger.log('Received pong, heartbeat acknowledged')
			_waiting_for_pong = false;
		# Handle response to request
		if message['type'] == 'response':
			var request_id: String = message.get('id', '');
			_logger.log('Received response for request id: %s' % request_id)
			if _pending_requests.has(request_id):
				var pending = _pending_requests[request_id];
				pending['callback'].call(message.get('data'));
			else:
				push_warning('[LFSocket]: Received response for unknown request id: %s' % request_id)
			return;
	
	# Handle server event
	if message.has('event'):
		var event: String = message['event'];
		var data: Variant = message.get('data', {});
		_logger.log('Received event: %s, listener count: %d' % [event, _listeners.get(event, []).size()])
		
		# Call specific listeners
		if _listeners.has(event):
			for callback in _listeners[event]:
				callback.call(data);
		
		# Call wildcard listeners
		for callback in _wildcard_listeners:
			callback.call(event, data);

func _handle_binary_message(packet: PackedByteArray) -> void:
	# Parse binary message with event name prefix
	if packet.size() < 4:
		push_warning('[LFSocket]: Binary message too short (size: %d)' % packet.size());
		return;
	
	var event_length := packet[0] | (packet[1] << 8) | (packet[2] << 16) | (packet[3] << 24);
	if packet.size() < 4 + event_length:
		push_warning('[LFSocket]: Binary message malformed - expected at least %d bytes, got %d' % [4 + event_length, packet.size()]);
		return;
	
	var event_bytes := packet.slice(4, 4 + event_length);
	var event := event_bytes.get_string_from_utf8();
	var data := packet.slice(4 + event_length);
	
	_logger.log('Binary message event: %s, data size: %d bytes' % [event, data.size()])
	
	# Trigger listeners with binary data
	if _listeners.has(event):
		_logger.log('Triggering %d listener(s) for binary event: %s' % [_listeners[event].size(), event])
		for callback in _listeners[event]:
			callback.call(data);
	else:
		_logger.log('No listeners registered for binary event: %s' % event)

func _start_heartbeat() -> void:
	if _options.heartbeat_interval_ms <= 0:
		_logger.log('Heartbeat disabled (interval: 0)')
		return;
	
	_logger.log('Starting heartbeat with interval: %dms' % _options.heartbeat_interval_ms)
	_last_heartbeat_time = Time.get_ticks_msec();

func _check_heartbeat() -> void:
	var now := Time.get_ticks_msec();
	
	# Check if we should send ping
	if now - _last_heartbeat_time >= _options.heartbeat_interval_ms:
		if _waiting_for_pong:
			# Didn't receive pong, connection might be dead
			push_warning('[LFSocket]: Heartbeat timeout, no pong received. Reconnecting...');
			disconnect_from_server(false);
			return;
		
		# Send ping
		_logger.log('Sending heartbeat ping')
		
		#ToDo: set service messages as params
		sendMessage({ 'type': 'ping' });
		_waiting_for_pong = true;
		_last_heartbeat_time = now;

func _schedule_reconnect() -> void:
	if !_options.auto_reconnect:
		_logger.log('Auto-reconnect disabled, not attempting to reconnect')
		return;
	
	if _options.max_reconnect_attempts > 0 && _reconnect_attempts >= _options.max_reconnect_attempts:
		_logger.error('Max reconnection attempts reached (%d attempts)' % _reconnect_attempts);
		_trigger_error('Max reconnection attempts reached');
		return;
	
	_reconnect_attempts += 1;
	_trigger_reconnecting(_reconnect_attempts);
	
	var tree := Engine.get_main_loop() as SceneTree;
	if !tree:
		_logger.error('Cannot schedule reconnect, SceneTree not available')
		return;
	
	_logger.log('Scheduling reconnection in %dms (attempt %d/%s)...' % [
		_current_reconnect_interval, 
		_reconnect_attempts, 
		'∞' if _options.max_reconnect_attempts == 0 else str(_options.max_reconnect_attempts)
	]);
	
	var reconnect_task := func() -> void:
		await tree.create_timer(_current_reconnect_interval / 1000.0).timeout;
		if _should_reconnect:
			_socket = WebSocketPeer.new();
			_attempt_connection();
			# Increase interval for next attempt (exponential backoff)
			_current_reconnect_interval = int(min(_current_reconnect_interval * _options.reconnect_decay, _options.max_reconnect_interval_ms));
	
	reconnect_task.call();

func _trigger_open() -> void:
	_logger.log('Triggering onOpen callbacks (%d registered)' % _on_open_callbacks.size())
	for callback in _on_open_callbacks:
		callback.call();

func _trigger_close() -> void:
	_logger.log('Triggering onClose callbacks (%d registered)' % _on_close_callbacks.size())
	for callback in _on_close_callbacks:
		callback.call();

func _trigger_error(msg: String) -> void:
	_logger.log('Error occurred: %s' % msg)
	error.emit(msg);
	for callback in _on_error_callbacks:
		callback.call(msg);

func _trigger_reconnecting(attempt: int) -> void:
	_logger.log('Reconnection attempt #%d' % attempt)
	reconnecting.emit(attempt);
	for callback in _on_reconnecting_callbacks:
		callback.call(attempt);
