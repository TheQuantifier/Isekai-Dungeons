# res://core/utils/enum_utils.gd
class_name EnumUtils

static func EtoS(enum_value: int, enum_type: Dictionary, output_type: String = "PascalCase") -> String:
	var keys := enum_type.keys()

	# Validate the index
	if enum_value < 0 or enum_value >= keys.size():
		push_error("Invalid enum_value passed.")
		return ""

	var raw_name: String = str(keys[enum_value])  # Index into keys by value

	match output_type:
		"all_caps":
			return raw_name
		"PascalCase", "Title Case":
			var words = raw_name.to_lower().split("_")
			for i in range(words.size()):
				words[i] = words[i].capitalize()
			return "".join(words) if output_type == "PascalCase" else " ".join(words)
		"snake_case":
			return raw_name.to_lower()
		"kebab-case":
			return raw_name.to_lower().replace("_", "-")
		"lowercase":
			return raw_name.to_lower().replace("_", "")
		_:
			push_warning("Unknown output_type '%s', returning raw_name." % output_type)
			return raw_name
