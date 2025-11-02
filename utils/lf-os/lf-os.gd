class_name LFOS;

## Detects the current operating system using Godot feature tags.
## Returns one of:
## 'windows' | 'linux' | 'macos' | 'android' | 'ios' | 'web'
static func detectOs() -> String:
	if OS.has_feature('windows'):
		return 'windows';
	elif OS.has_feature('linux'):
		return 'linux';
	elif OS.has_feature('macos'):
		return 'macos';
	elif OS.has_feature('android'):
		return 'android';
	elif OS.has_feature('ios'):
		return 'ios';
	elif OS.has_feature('web') or OS.has_feature('wasm32'):
		return 'web';
	return OS.get_name().to_lower(); # fallback;


## Detects the current CPU/target architecture using Godot feature tags.
## Returns one of:
## 'x86_64' | 'arm64' | 'arm32' | 'wasm32'
## Falls back to 'x86_64' if nothing matches.
static func detectArch() -> String:
	if OS.has_feature('x86_64'):
		return 'x86_64';
	elif OS.has_feature('arm64'):
		return 'arm64';
	elif OS.has_feature('arm32'):
		return 'arm32';
	elif OS.has_feature('wasm32'):
		return 'wasm32';
	return 'x86_64'; # safe default;


## Chooses a preferred llama.cpp backend based on OS and GPU.
## - macOS → 'metal'
## - Windows/Linux with NVIDIA → 'cuda'
## - Else if Vulkan feature present → 'vulkan'
## - Otherwise → 'cpu'
## Param:
## 	osName: result from detectOs()
## Returns:
## 	'metal' | 'cuda' | 'vulkan' | 'cpu'
static func selectBackend(osName: String) -> String:
	if osName == 'macos':
		return 'metal';
	var vendor := safeGetGpuVendor();
	return 'cuda' if ((osName == 'windows' or osName == 'linux') and vendor.findn('nvidia') != -1) else \
		('vulkan' if OS.has_feature('vulkan') else 'cpu');


## Safely reads the GPU vendor (lowercased). Returns '' if unavailable.
## Uses RenderingServer when present; avoids exceptions (Godot has no try/catch).
static func safeGetGpuVendor() -> String:
	if RenderingServer.has_method('get_video_adapter_vendor'):
		var v := RenderingServer.get_video_adapter_vendor();
		return v.to_lower() if typeof(v) == TYPE_STRING else '';
	return '';
