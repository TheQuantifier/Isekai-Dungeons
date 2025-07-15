# res://core/character/character.gd
extends Resource
class_name Character

@warning_ignore("shadowed_global_identifier")
const StatTypes = preload("res://core/stats/stat_types.gd")
@warning_ignore("shadowed_global_identifier")
const Equipment = preload("res://core/equipment/equipment.gd")
@warning_ignore("shadowed_global_identifier")
const Backpack = preload("res://core/character/backpack.gd")
@warning_ignore("shadowed_global_identifier")
const Armor = preload("res://core/equipment/armor.gd")
@warning_ignore("shadowed_global_identifier")
const Potion = preload("res://core/equipment/potion.gd")

# --- Signals ---
signal health_changed(new_health: int)
signal gold_changed(new_gold: int)
signal item_equipped(item: Equipment)
signal item_unequipped(item: Equipment)
signal potion_consumed(potion: Potion)

# --- Core Properties ---
@export var char_id: String = ""
@export var char_age: float = 0
@export var gender: String = "male"  # Options: "male", "female"
@export var model_path: String = ""
@export var current_health: int = 10
@export var gold: int = 0

# --- Inventory System ---
var backpack: Backpack
@export var equipped_items: Array[Equipment] = []

# --- Stat Maps ---
@export var strength_stats: Dictionary = {}
@export var defense_stats: Dictionary = {}

func _init() -> void:
	backpack = Backpack.new(30, self)

	for s_type in StatTypes.StrengthType.values():
		strength_stats[s_type] = 0
	for d_type in StatTypes.DefenseType.values():
		defense_stats[d_type] = 0

# ---------- Stat Manipulation ----------
func add_gold(amount: int) -> void:
	gold += amount
	emit_signal("gold_changed", gold)

func add_health(amount: int) -> void:
	current_health += amount
	emit_signal("health_changed", current_health)

func get_strength(s_type: int) -> int:
	return strength_stats.get(s_type, 0)

func add_strength(s_type: int, amount: int) -> void:
	strength_stats[s_type] = get_strength(s_type) + amount

func get_defense(d_type: int) -> int:
	return defense_stats.get(d_type, 0)

func add_defense(d_type: int, amount: int) -> void:
	defense_stats[d_type] = get_defense(d_type) + amount

func get_total_defense() -> int:
	var total := 0
	for value in defense_stats.values():
		total += value
	return total

# ---------- Equipment Logic ----------
func equip(item: Equipment) -> String:
	if item.equip_type == Equipment.EquipmentType.POTION:
		return "Potions cannot be equipped. Try consuming them instead."

	if item.is_equipped:
		return "%s is already equipped." % item.item_id

	if not backpack.contains(item):
		return "Sorry, %s is not in your inventory." % item.item_id

	backpack.remove(item)
	equipped_items.append(item)
	add_health(item.health_mod)
	add_strength(StatTypes.StrengthType.PHYSICAL, item.strength_mod)
	item.is_equipped = true
	emit_signal("item_equipped", item)

	if item is Armor:
		add_defense(StatTypes.DefenseType.HEAD, item.head_defense)
		add_defense(StatTypes.DefenseType.CHEST, item.chest_defense)
		add_defense(StatTypes.DefenseType.LEG, item.leg_defense)
		add_defense(StatTypes.DefenseType.FEET, item.feet_defense)

	return "%s equipped successfully." % item.item_id

func unequip(item: Equipment) -> String:
	if not equipped_items.has(item):
		return "Sorry, %s is not equipped." % item.item_id

	equipped_items.erase(item)
	add_health(-item.health_mod)
	add_strength(StatTypes.StrengthType.PHYSICAL, -item.strength_mod)
	item.is_equipped = false
	backpack.add(item)
	emit_signal("item_unequipped", item)

	if item is Armor:
		add_defense(StatTypes.DefenseType.HEAD, -item.head_defense)
		add_defense(StatTypes.DefenseType.CHEST, -item.chest_defense)
		add_defense(StatTypes.DefenseType.LEG, -item.leg_defense)
		add_defense(StatTypes.DefenseType.FEET, -item.feet_defense)

	return "%s unequipped successfully." % item.item_id

# ---------- Item Transactions ----------
func sell(item: Equipment) -> String:
	if backpack.contains(item):
		backpack.remove(item)
		add_gold(item.get_sell_cost())
		return "%s sold for %d gold." % [item.item_id, item.get_sell_cost()]
	return "Sorry, %s is not in your inventory." % item.item_id

func sell_to(item: Equipment, buyer: Character) -> String:
	if not backpack.contains(item):
		return "Sorry, %s is not in your inventory." % item.item_id
	if buyer.gold < item.get_sell_cost():
		return "Sorry, %s does not have enough gold." % buyer.char_id

	backpack.remove(item)
	add_gold(item.get_sell_cost())
	buyer.add_gold(-item.get_sell_cost())
	buyer.backpack.add(item)

	return "%s sold to %s for %d gold." % [item.item_id, buyer.char_id, item.get_sell_cost()]

func trade(my_item: Equipment, partner: Character, their_item: Equipment) -> String:
	if not (backpack.contains(my_item) and partner.backpack.contains(their_item)):
		return "Trade failed: one or both items are not in the respective inventories."

	backpack.remove(my_item)
	partner.backpack.remove(their_item)
	backpack.add(their_item)
	partner.backpack.add(my_item)

	return "You traded %s for %s with %s." % [my_item.item_id, their_item.item_id, partner.char_id]

# ---------- Potion Consumption ----------
func consume_potion(potion: Potion) -> String:
	if not backpack.contains(potion):
		return "You don't have that potion."
	if potion.is_consumed:
		return "That potion has already been used."

	potion.consume(self)
	backpack.remove(potion)
	emit_signal("potion_consumed", potion)
	return "%s consumed." % potion.item_id

# ---------- Stat Reset ----------
func reset_stats() -> void:
	for s_type in StatTypes.StrengthType.values():
		strength_stats[s_type] = 0
	for d_type in StatTypes.DefenseType.values():
		defense_stats[d_type] = 0
	current_health = 10
	gold = 0
	emit_signal("health_changed", current_health)
	emit_signal("gold_changed", gold)

# ---------- Debug Info ----------
func display_equipped() -> String:
	var result := "ITEM ID\t+HEALTH:+STRENGTH\n"
	for item in equipped_items:
		result += "%s\t%d:%d\n" % [item.item_id, item.health_mod, item.strength_mod]
	return result

func describe() -> String:
	return "Character{id='%s', age=%f, health=%d, gold=%d}" % [char_id, char_age, current_health, gold]

func data() -> String:
	var s := "================ Character Data ================\n"
	s += "Name: %s\nAge: %f\nHealth: %d\nGold: %d\n\n" % [char_id, char_age, current_health, gold]

	s += "-- Strength Stats --\n"
	for k in strength_stats.keys():
		s += "%s: %d\n" % [str(k), strength_stats[k]]

	s += "\n-- Defense Stats --\n"
	for k in defense_stats.keys():
		s += "%s: %d\n" % [str(k), defense_stats[k]]

	s += "\n-- Equipped Items --\n"
	for item in equipped_items:
		s += "%s | +Health: %d, +Strength: %d\n" % [item.item_id, item.health_mod, item.strength_mod]

	s += "================================================"
	return s
