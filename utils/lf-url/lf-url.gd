class_name LFUrl;
extends RefCounted;

var _url := '';
var data := LFUrlDef.new();

signal update;


func _init(url := '') -> void:
	if url != '':
		setUrl(url);


func setUrl(url: String):
	_url = url;
	data = parse(url);
	update.emit();


func isEmpty():
	return _url.is_empty();


static func parse(url: String) -> LFUrlDef:
	# Very small URL parser for http/https
	# Matches: scheme://host[:port][/path][?query]
	var data := LFUrlDef.new();
	var re := RegEx.new();
	re.compile("^(?P<scheme>https?)://(?P<host>[^/:?#]+)(?::(?P<port>\\d+))?(?P<path>/[^?#]*)?(?:\\?(?P<query>[^#]*))?$");
	var m := re.search(url);
	if m == null:
		return data;
	
	data.scheme = m.get_string("scheme").to_lower();
	data.host = m.get_string("host");
	var port_str := m.get_string("port");
	data.port = int(port_str) if port_str != "" else 0;
	data.path = m.get_string("path");
	data.query = m.get_string("query");
	
	return data;


class LFUrlDef extends Resource:
	var scheme: String;
	var host: String;
	var port: int;
	var path: String;
	var query: String;
	func isNull(): return !scheme && !host && !port && !path && !query;
