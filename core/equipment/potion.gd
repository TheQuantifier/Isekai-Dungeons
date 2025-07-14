# res://core/equipment/potion.gd
extends Equipment
class_name Potion

# === Properties ===
var is_consumed: bool = false

# === Initialization ===
func _init(
	_id: String = "",
	_level: int = 1,
	_strength_mod: int = 0,
	_health_mod: int = 0,
	_cost: int = 0,
	_equipped: bool = false,
	_display_name: String = ""
) -> void:
	super._init(
		_id, _level, _strength_mod, _health_mod, _cost,
		EquipmentType.POTION, _equipped, _display_name
	)

# === Overrides ===
func is_equippable() -> bool:
	return false

# === Core Logic ===
func consume(target: Character) -> String:
	if is_consumed:
		return "%s has already been used." % display_name

	if not target:
		return "No target to use potion on."

	# Apply stat effects
	apply_to(target)
	is_consumed = true
	return "%s consumed successfully." % display_name

# === Debug Info ===
func describe() -> String:
	var consumed_text := "Yes" if is_consumed else "No"
	return "[Potion: %s] Lv%d | +%d HP, +%d STR | Used: %s" % [
		display_name, level, health_mod, strength_mod, consumed_text
	]
