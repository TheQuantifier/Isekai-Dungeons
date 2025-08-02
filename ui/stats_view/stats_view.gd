extends Control

@warning_ignore("shadowed_global_identifier")
const StatTypes = preload("res://core/stats/stat_types.gd")
@warning_ignore("shadowed_global_identifier")
const Character = preload("res://core/character/character.gd")

# --- Main Info ---
@onready var name_label = get_node("MainInfo/NameLabel")
@onready var gender_label = get_node("MainInfo/GenderLabel")
@onready var age_label = get_node("MainInfo/AgeLabel")
@onready var class_label = get_node("MainInfo/ClassLabel")

# --- Main Stats ---
@onready var health_label = get_node("MainStats/HealthLabel")
@onready var mana_label = get_node("MainStats/ManaLabel")
@onready var wealth_label = get_node("MainStats/WealthLabel")

# --- Defense Stats ---
@onready var total_defense_label = get_node("DefenseStats/TotalDefenseLabel")
@onready var head_def_label = get_node("DefenseStats/DefEnums/HeadDefLabel")
@onready var chest_def_label = get_node("DefenseStats/DefEnums/ChestDefLabel")
@onready var leg_def_label = get_node("DefenseStats/DefEnums/LegDefLabel")
@onready var feet_def_label = get_node("DefenseStats/DefEnums/FeetDefLabel")
@onready var shield_def_label = get_node("DefenseStats/DefEnums/ShieldDefLabel")

# --- Strength Stats ---
@onready var physical_strength_label = get_node("StrengthStats/StrengthEnums/PhysicalStrengthLabel")
@onready var magical_strength_label = get_node("StrengthStats/StrengthEnums/MagicalStrengthLabel")
@onready var technical_strength_label = get_node("StrengthStats/StrengthEnums/TechnicalStrengthLabel")
@onready var total_strength_label = get_node("StrengthStats/TotalStrengthLabel")


# --- Resistance Stats ---
@onready var physical_resistance_label = get_node("ResistanceStats/ResistanceEnums/PhysicalResistanceLabel")
@onready var magical_resistance_label = get_node("ResistanceStats/ResistanceEnums/MagicalResistanceLabel")

func _ready() -> void:
	if game_manager.current_character:
		show_stats(game_manager.current_character)
	else:
		print("No character found in game_manager.")

func show_stats(c: Character) -> void:
	# Clear all fields
	name_label.text = ""
	gender_label.text = ""
	age_label.text = ""

	health_label.text = ""
	mana_label.text = ""  # Placeholder
	wealth_label.text = ""

	total_defense_label.text = ""

	head_def_label.text = ""
	chest_def_label.text = ""
	leg_def_label.text = ""
	feet_def_label.text = ""
	shield_def_label.text = ""

	physical_strength_label.text = ""
	magical_strength_label.text = ""
	technical_strength_label.text = ""
	total_strength_label.text = ""  # Placeholder

	# Populate values
	name_label.text = "Name:  " + c.char_id
	class_label.text = "Class:  " + StatTypes.ClassType.keys()[c.class_type]
	gender_label.text = "Gender:  " + c.gender.capitalize()
	age_label.text = "Age:  " + str(c.char_age)

	health_label.text = "Health:  " + str(c.current_health) + "/" + str(c.max_health)
	mana_label.text = "Mana: " + str(c.current_mana) + "/" + str(c.max_mana)
	wealth_label.text = "Gold:  " + str(c.gold)

	total_defense_label.text = "Total Defense:   " + str(c.get_total_defense())
	head_def_label.text = str(c.get_defense(StatTypes.DefenseType.HEAD))
	chest_def_label.text = str(c.get_defense(StatTypes.DefenseType.CHEST))
	leg_def_label.text = str(c.get_defense(StatTypes.DefenseType.LEG))
	feet_def_label.text = str(c.get_defense(StatTypes.DefenseType.FEET))
	shield_def_label.text = str(c.get_defense(StatTypes.DefenseType.SHIELD))

	total_strength_label.text = "Total Strength:  " + str(c.get_total_strength())
	physical_strength_label.text = str(c.get_strength(StatTypes.StrengthType.PHYSICAL))
	magical_strength_label.text = str(c.get_strength(StatTypes.StrengthType.MAGICAL))
	technical_strength_label.text = str(c.get_strength(StatTypes.StrengthType.TECHNICAL))

	physical_resistance_label.text = str(c.get_resistance(StatTypes.ResistanceType.PHYSICAL)) + "%"
	magical_resistance_label.text = str(c.get_resistance(StatTypes.ResistanceType.MAGICAL)) + "%"
func _on_button_pressed() -> void:
	game_manager.go_to_main_menu()
