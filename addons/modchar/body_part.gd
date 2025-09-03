# res://body_part.gd
extends Resource
class_name BodyPart

## Enum to categorize high-level body parts for equipment sockets.
## You can extend this as needed; editor UI reads these dynamically.
## NOTE: The string names are also used as default socket node names.

enum Kind {
	HEAD,
	NECK,
	CHEST,
	BACK,
	HIPS,
	LEFT_SHOULDER,
	RIGHT_SHOULDER,
	LEFT_HAND,
	RIGHT_HAND,
	LEFT_FOOT,
	RIGHT_FOOT,
}

static func names() -> Array[String]:
	var a: Array[String] = []
	for i in Kind.values():
		a.append(Kind.keys()[i])
	return a
