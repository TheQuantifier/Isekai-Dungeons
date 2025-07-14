# res://core/equipment/weapon.gd
extends Equipment
class_name Weapon

# === Optional Future Expansion ===
# For now, weapons inherit strength_mod from Equipment
# You can later add: damage_type, crit_chance, range, etc.

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
		EquipmentType.WEAPON, _equipped, _display_name
	)

# === Debug Info ===
func describe() -> String:
	return "[Weapon: %s] Lv%d | +%d HP, +%d STR | Cost: %d" % [
		display_name, level, health_mod, strength_mod, cost
	]
