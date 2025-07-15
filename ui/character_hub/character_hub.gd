extends Control
class_name CharacterHub

func _ready():
	# You can preload character data or UI bindings here if needed
	pass

func _on_play_pressed():
	game_manager.change_scene("res://scenes/game_world/game_world.tscn")

func _on_edit_character_pressed():
	# Implement this when character editing is ready
	game_manager.change_scene("res://scenes/character_customization/character_customization.tscn")

func _on_view_stats_pressed():
	game_manager.change_scene("res://ui/stats_view/stats_view.tscn")

func _on_log_out_pressed():
	game_manager.change_scene("res://ui/main_menu/main_menu.tscn")
