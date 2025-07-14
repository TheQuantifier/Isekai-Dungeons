# res://core/equipment/armor.gd
extends Equipment
class_name Armor

# --- Individual Defense Stats ---
var head_defense: int = 0
var chest_defense: int = 0
var leg_defense: int = 0
var foot_defense: int = 0

# --- Initialization ---
func _init(
	_id: String,
	_level: int,
	_strength_mod: int,
	_health_mod: int,
	_cost: int,
	_head: int = 0,
	_chest: int = 0,
	_leg: int = 0,
	_foot: int = 0,
	_equipped: bool = false
) -> void:
	super._init(_id, _level, _strength_mod, _health_mod, _cost, EquipmentType.ARMOR, _equipped)
	head_defense = _head
	chest_defense = _chest
	leg_defense = _leg
	foot_defense = _foot

# --- Utility Methods ---

# Returns the sum of all defense stats for this armor item.
func get_total_defense() -> int:
	return head_defense + chest_defense + leg_defense + foot_defense

# Returns the defense value for a given slot (uses StatTypes.DefenseType enum).
func get_defense_by_slot(slot: int) -> int:
	match slot:
		StatTypes.DefenseType.HEAD: return head_defense
		StatTypes.DefenseType.CHEST: return chest_defense
		StatTypes.DefenseType.LEG: return leg_defense
		StatTypes.DefenseType.FEET: return foot_defense
		_: return 0

# Returns a formatted string with armor stats for debug or UI display.
func describe() -> String:
	return "[Armor] %s | DEF(H:%d C:%d L:%d F:%d) | +%d HP | +%d STR" % [
		item_id, head_defense, chest_defense, leg_defense, foot_defense, health_mod, strength_mod
	]

# Indicates whether the item can be equipped (always true for armor).
func is_equippable() -> bool:
	return true
