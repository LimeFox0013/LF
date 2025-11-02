class_name LFShell

# Runs a shell command cross-platform
# @param command: String command (e.g. 'echo Hello')
# @param workDir: Optional working directory
# @return: [exitCode, outputLines]
#func execute(command: String, workDir: String = "") -> Array:
	#var shellCmd: Array = []
	#var output := []
#
	#if OS.has_feature("windows"):
		#shellCmd = ["cmd", "/c", command]
	#else:
		#shellCmd = ["sh", "-c", command]
#
	#var result := OS.execute(shellCmd[0], shellCmd.slice(1), true, output, workDir)
	#return [result, output]
