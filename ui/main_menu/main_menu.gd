extends Control
class_name MainMenu

@onready var play_button: Button = $CanvasLayer/UI/CenterContainer/VBoxContainer/PlayButton

func _ready():
	if play_button and game_manager.current_character:
		var path := game_manager.current_character.model_path
		if path == "" or path == null:
			play_button.disabled = true
			play_button.tooltip_text = "Please select a gender in Character Edit before playing."
		else:
			play_button.disabled = false
			play_button.tooltip_text = ""
	else:
		push_error("PlayButton or current_character is missing!")

func _on_play_pressed():
	if play_button and not play_button.disabled:
		game_manager.go_to_game_world()

func _on_edit_character_pressed():
	game_manager.go_to_character_customization()

func _on_view_stats_pressed():
	game_manager.go_to_view_stats()

func _on_log_out_pressed():
	game_manager.go_to_login_page()
