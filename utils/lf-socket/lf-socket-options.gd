class_name LFSocketOptions;


var auto_reconnect: bool = true
var reconnect_interval_ms: int = 1000
var max_reconnect_interval_ms: int = 30000
var reconnect_decay: float = 1.5
var max_reconnect_attempts: int = 0  # 0 = infinite
var heartbeat_interval_ms: int = 30000  # Send ping every 30s
var heartbeat_timeout_ms: int = 5000  # Wait 5s for pong
var queue_offline_messages: bool = true
var max_queue_size: int = 100
