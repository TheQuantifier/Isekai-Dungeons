extends Resource
class_name Equipment

@warning_ignore("shadowed_global_identifier")
const StatTypes = preload("res://core/stats/stat_types.gd")

# === Properties ===
@export var item_id: String = ""          # Unique internal identifier
@export var display_name: String = ""     # Shown to players
@export var level: int = 1
@export var strength_mod: int = 0
@export var health_mod: int = 0
@export var cost: int = 0
@export var is_equipped: bool = false

# === Equipment Type ===
enum EquipmentType { ARMOR, WEAPON, POTION }
@export var equip_type: EquipmentType = EquipmentType.WEAPON

# === Constants ===
const SELL_COST_RATIO := 0.6

# === Initialization ===
func _init(
	_id: String = "",
	_level: int = 1,
	_strength_mod: int = 0,
	_health_mod: int = 0,
	_cost: int = 0,
	_type: EquipmentType = EquipmentType.WEAPON,
	_equipped: bool = false,
	_display_name: String = ""
) -> void:
	item_id = _id
	level = _level
	strength_mod = _strength_mod
	health_mod = _health_mod
	cost = _cost
	equip_type = _type
	is_equipped = _equipped
	display_name = _display_name if _display_name != "" else _id.capitalize()

# === Core Methods ===
func get_sell_cost() -> int:
	return int(cost * SELL_COST_RATIO)

func describe() -> String:
	return "[%s] Lv%d | +%d HP, +%d STR | Cost: %d" % [
		display_name, level, health_mod, strength_mod, cost
	]

func apply_to(target: Character) -> void:
	if target:
		target.add_health(health_mod)
		target.add_strength(StatTypes.StrengthType.PHYSICAL, strength_mod)

func remove_from(target: Character) -> void:
	if target:
		target.add_health(-health_mod)
		target.add_strength(StatTypes.StrengthType.PHYSICAL, -strength_mod)

func can_be_equipped_by(target: Character) -> bool:
	# Customize for restrictions (level, class, etc.)
	return target.age >= level

func is_equippable() -> bool:
	# Override in Potion.gd to return false
	return true

func clone() -> Equipment:
	var new_equipment := self.duplicate(true)
	new_equipment.is_equipped = false
	return new_equipment
