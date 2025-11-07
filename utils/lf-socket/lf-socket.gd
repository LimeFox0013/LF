class_name LFSocket;
extends RefCounted;

## WebSocket client for communicating with NestJS backend
## Supports both unidirectional messages and request/response patterns
## All communication is JSON-based with advanced features:
## - Auto-reconnection with exponential backoff
## - Heartbeat/ping-pong to keep connection alive
## - Connection lifecycle callbacks
## - Message queue for offline messages
## - Binary data support

static var _instance: LFSocketInstance;
static var _logger := LFLogger.new(['[LFSocket]:']);


## Connect to WebSocket server
## @param url: WebSocket URL (e.g., 'ws://localhost:3000')
## @param options: LFSocketOptions for customizing behavior
## @return: true if connection initiated successfully
static func connectWS(url: String, options: LFSocketOptions = null) -> bool:
	_logger.log('connectWS() called with URL: %s' % url)
	
	if _instance && _instance.isConnected():
		_logger.warning('Already connected. Disconnect first.');
		return false;
	
	if options == null:
		options = LFSocketOptions.new()
		_logger.log('Using default LFSocketOptions')
	else:
		_logger.log('Using custom LFSocketOptions - auto_reconnect: %s, reconnect_interval: %dms' % [options.auto_reconnect, options.reconnect_interval_ms])
	
	_instance = LFSocketInstance.new();
	return _instance.connect_to_server(url, options);

## Disconnect from WebSocket server
## @param disable_reconnect: If true, prevents auto-reconnection
static func disconnectWS(disable_reconnect: bool = true) -> void:
	_logger.log('disconnectWS() called, disable_reconnect: %s' % disable_reconnect)
	if _instance:
		_instance.disconnect_from_server(disable_reconnect);
		if disable_reconnect:
			_instance = null;
	else:
		_logger.log('disconnectWS() called but no instance exists')

## Check if connected
static func isConnected() -> bool:
	return _instance != null && _instance.isConnected();

## Send unidirectional message (fire and forget)
## @param event: Event name
## @param data: Data to send (will be converted to JSON)
## @param queue_if_offline: Queue message if not connected (requires queue_offline_messages enabled)
static func emit(event: String, data: Variant = {}, queue_if_offline: bool = true) -> void:
	if !_instance:
		_logger.error('Not connected. Call connectWS() first.');
		return;
	_logger.log('emit() called for event: %s' % event)
	
	_instance.sendMessage(event, data, queue_if_offline);

## Send request and wait for response (HTTP-like)
## @param event: Event name
## @param data: Data to send (will be converted to JSON)
## @param timeout_ms: Timeout in milliseconds (0 = no timeout)
## @return: Response data or null on error/timeout
static func request(event: String, data: Variant = {}, timeout_ms: int = 5000) -> Variant:
	if !_instance:
		_logger.error('Not connected. Call connectWS() first.');
		return null;
	_logger.log('request() called for event: %s, timeout: %dms' % [event, timeout_ms])
	return await _instance.request_message(event, data, timeout_ms);

## Listen to server events
## @param event: Event name to listen for, or '*' for all events
## @param callback: Callable to execute when event received
static func on(event: String, callback: Callable) -> void:
	if !_instance:
		_logger.error('Not connected. Call connectWS() first.');
		return;
	_logger.log('Registered listener for event: %s' % event)
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
		return { 'connected': false, 'url': '' };
	return _instance.getStatus();

## Connection lifecycle callbacks
## Register callback for when connection opens
static func onOpen(callback: Callable) -> void:
	if !_instance:
		_instance = LFSocketInstance.new();
	_instance.on_open(callback);

## Register callback for when connection closes
static func onClose(callback: Callable) -> void:
	if !_instance:
		_instance = LFSocketInstance.new();
	_instance.on_close(callback);

## Register callback for when error occurs
static func onError(callback: Callable) -> void:
	if !_instance:
		_instance = LFSocketInstance.new();
	_instance.on_error(callback);

## Register callback for reconnection attempts
static func onReconnecting(callback: Callable) -> void:
	if !_instance:
		_instance = LFSocketInstance.new();
	_instance.on_reconnecting(callback);

## Send binary data
## @param event: Event name
## @param data: Binary data as PackedByteArray
static func emitBinary(event: String, data: PackedByteArray) -> void:
	if !_instance:
		_logger.error('Not connected. Call connectWS() first.');
		return;
	_instance.emit_binary(event, data);

## Get number of queued messages
static func getQueueSize() -> int:
	if !_instance:
		return 0;
	return _instance.get_queue_size();

## Clear message queue
static func clearQueue() -> void:
	if _instance:
		_instance.clear_queue();

## Force reconnection attempt
static func reconnect() -> void:
	if _instance:
		_instance.force_reconnect();
