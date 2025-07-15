extends Control
class_name CharacterHub

func _ready():
	# You can preload character data or UI bindings here if needed
	pass

func _on_play_pressed():
	game_manager.go_to_game_world()

func _on_edit_character_pressed():
	game_manager.go_to_character_customization()

func _on_view_stats_pressed():
	game_manager.go_to_view_stats()

func _on_log_out_pressed():
	game_manager.go_to_login_page()
