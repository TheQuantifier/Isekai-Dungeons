class_name GeneralUtilities

const DEBUG: bool = true # Global debug toggle

# Debug print function
static func dprint(message: String, label: String = "DEBUG") -> void:
	if DEBUG:
		print("[%s] %s" % [label, message])
