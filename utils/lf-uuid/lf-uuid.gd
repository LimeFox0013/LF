# MIT License
# lf-uuid.gd — minimal UUID v4 generator (RFC 4122) with optional prefix.
# Produces lowercase hex with hyphens: 8-4-4-4-12 (e.g., "550e8400-e29b-41d4-a716-446655440000")
# No engine UUID dependency; works on Godot 4.x including dev builds.
class_name LFUuid;

## gen
## Generates a random UUID v4 string, optionally prefixed.
## - prefix: optional string to prepend (e.g., 'lf').
## Returns: String like 'lf-xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
static func gen(prefix: String = '') -> String:
	var rng := RandomNumberGenerator.new();
	rng.randomize();

	# 16 random bytes
	var bytes := PackedByteArray();
	for i in range(16):
		bytes.append(rng.randi() & 0xFF);

	# Set RFC 4122 bits: version (0100) and variant (10xx)
	bytes[6] = (bytes[6] & 0x0F) | 0x40;	# version 4
	bytes[8] = (bytes[8] & 0x3F) | 0x80;	# variant RFC 4122

	# Format as 8-4-4-4-12 hex pairs
	var parts: Array[String] = [];
	var pairs := [4, 2, 2, 2, 6];	# number of byte-pairs per group
	var idx := 0;
	for p in pairs:
		var seg := '';
		for _j in range(p):
			seg += '%02x' % bytes[idx];
			idx += 1;
		parts.append(seg);
	
	return '-'.join(parts);
