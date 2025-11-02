class_name LFHTTP;

const _REDIRECT_CODES := [301, 302, 303, 307, 308]

static func _request(
	method: HTTPClient.Method,
	url: String,
	headers: Dictionary,
	body: String,
	timeout_ms := 0,
) -> Dictionary:
	var seen := 0
	var current := url
	while seen < 5:
		var res := await _single_request(method, current, headers, body, timeout_ms)
		if res.ok and _REDIRECT_CODES.has(res.status):
			var loc: String = (res.headers.get("location", res.headers.get("Location", "")) as String)
			if loc.is_empty(): return res
			current = _absolutize(current, loc)
			seen += 1
			continue
		return res
	return { "ok": false, "status": 0, "error": "Too many redirects" }

static func _single_request(
	method: HTTPClient.Method,
	url: String,
	headers: Dictionary,
	body: String,
	timeout_ms := 0,
) -> Dictionary:
	var u := _parse_url(url)
	if u.is_empty():
		return { "ok": false, "status": 0, "error": "Invalid URL" }

	var use_tls: bool = u.scheme == "https"
	var port: int = u.port if u.port > 0 else (443 if use_tls else 80)
	var path: String = u.path
	if path.is_empty(): path = "/"
	if !u.query.is_empty(): path += "?" + u.query

	var client := HTTPClient.new()
	var tls = TLSOptions.client() if use_tls else null;
	var err := client.connect_to_host(u.host, port, tls)
	if err != OK:
		return { "ok": false, "status": 0, "error": "Connect error %s" % err }

	var start := Time.get_ticks_msec()
	var tree := Engine.get_main_loop() as SceneTree

	while client.get_status() in [HTTPClient.STATUS_CONNECTING, HTTPClient.STATUS_RESOLVING]:
		client.poll()
		if timeout_ms != 0 && Time.get_ticks_msec() - start > timeout_ms:
			return { "ok": false, "status": 0, "error": "Connect timeout" }
		await tree.process_frame

	if client.get_status() != HTTPClient.STATUS_CONNECTED:
		return { "ok": false, "status": 0, "error": "Not connected" }

	var header_list := PackedStringArray()
	var all_headers := headers.duplicate()
	all_headers.set("Host", u.host)
	all_headers.set("User-Agent", "GodotHTTPClient/4.x")
	all_headers.set("Accept-Encoding", "identity")
	for k in all_headers.keys():
		header_list.push_back("%s: %s" % [k, str(all_headers[k])])

	err = client.request(method, path, header_list, body)
	if err != OK:
		return { "ok": false, "status": 0, "error": "Request error %s" % err }

	while !client.has_response():
		client.poll()
		if timeout_ms != 0 && Time.get_ticks_msec() - start > timeout_ms:
			return { "ok": false, "status": 0, "error": "Header timeout" }
		await tree.process_frame

	var status := client.get_response_code()
	var hdrs := client.get_response_headers_as_dictionary()

	var bytes := PackedByteArray()
	while client.get_status() == HTTPClient.STATUS_BODY:
		client.poll()
		var chunk := client.read_response_body_chunk()
		if chunk.size() > 0:
			bytes.append_array(chunk)
			start = Time.get_ticks_msec()
		if timeout_ms != 0 && Time.get_ticks_msec() - start > timeout_ms:
			return { "ok": false, "status": status, "headers": hdrs, "error": "Body timeout", "body_bytes": bytes }
		await tree.process_frame

	var text := bytes.get_string_from_utf8() if bytes.size() > 0 else ""
	var json_val = null
	var ct := str(hdrs.get("content-type", hdrs.get("Content-Type", ""))).to_lower()
	if ct.find("application/json") != -1:
		var parsed = JSON.parse_string(text)
		if parsed != null:
			json_val = parsed

	return {
		"ok": status >= 200 and status < 400,
		"status": status,
		"headers": hdrs,
		"body_bytes": bytes,
		"body_text": text,
		"json": json_val
	}

	# ---- helpers ----

static func _parse_url(url: String) -> Dictionary:
	# Very small URL parser for http/https
	# Matches: scheme://host[:port][/path][?query]
	var re := RegEx.new()
	re.compile("^(?P<scheme>https?)://(?P<host>[^/:?#]+)(?::(?P<port>\\d+))?(?P<path>/[^?#]*)?(?:\\?(?P<query>[^#]*))?$")
	var m := re.search(url)
	if m == null:
		return {}
	var scheme := m.get_string("scheme").to_lower()
	var host := m.get_string("host")
	var port_str := m.get_string("port")
	var port := int(port_str) if port_str != "" else 0
	var path := m.get_string("path")
	var query := m.get_string("query")
	return {
		"scheme": scheme,
		"host": host,
		"port": port,
		"path": path,
		"query": query
	}

static func _absolutize(base_url: String, loc: String) -> String:
	# Absolute?
	if loc.begins_with("http://") or loc.begins_with("https://"):
		return loc
	# Parse base
	var b := _parse_url(base_url)
	if b == null:
		return loc
	# Root-relative
	if loc.begins_with("/"):
		return "%s://%s%s" % [b.scheme, b.host, loc]
	# Path-relative
	var base_path: String = b.path
	if base_path == "" or !base_path.begins_with("/"):
		base_path = "/"
	if !base_path.ends_with("/"):
		base_path = base_path.get_base_dir() + "/"
	return "%s://%s%s%s%s" % [b.scheme, b.host, base_path, loc, ("" if b.query == "" else "")]

static func findFreeTcpPort(
	ip := "127.0.0.1",
	from: int = 3000,
	to: int = 4000,
) -> int:
	var s := TCPServer.new()
	
	# 1) Try preferred ports first
	for p in range(from, to):
		print('p == ', p)
		if s.listen(p, ip) == OK:
			print('Port ', p, ' is free');
			s.stop()
			print('stopped connection to ', p, ' ', !s.is_listening())
			return p;
		s.stop();
	push_error('No free port between {from} to {to}'.format({ 'from': from, 'to': to }));
	return from;
