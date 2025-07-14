# res://ui/stats_view/stats_view.gd
extends Control

@onready var left_vbox := $MarginContainer/HBoxContainer/LeftVBox
@onready var right_vbox := $MarginContainer/HBoxContainer/RightVBox

func _ready() -> void:
	if game_manager.current_character:
		update_stats(game_manager.current_character)
	print("LeftVBox children: ", left_vbox.get_children())
	print("RightVBox children: ", right_vbox.get_children())

func update_stats(character) -> void:
	left_vbox.get_node("Name").text = "Name: %s" % character.char_id
	left_vbox.get_node("Age").text = "Age: %.1f" % character.char_age
	left_vbox.get_node("Health").text = "Health: %d" % character.current_health
	left_vbox.get_node("Gold").text = "Gold: %d" % character.gold

	var def_stats = character.defense_stats
	var str_stats = character.strength_stats

	for i in StatTypes.DefenseType.values():
		var key_name = StatTypes.DefenseType.keys()[StatTypes.DefenseType.values().find(i)]
		var label_name = "Defense_%s" % key_name
		right_vbox.get_node(label_name).text = "%s: %d" % [key_name, def_stats.get(i, 0)]

	for i in StatTypes.StrengthType.values():
		var key_name = StatTypes.StrengthType.keys()[StatTypes.StrengthType.values().find(i)]
		var label_name = "Strength_%s" % key_name
		right_vbox.get_node(label_name).text = "%s: %d" % [key_name, str_stats.get(i, 0)]


func _on_back_button_pressed() -> void:
	game_manager.change_scene("res://ui/character_hub/character_hub.tscn")
