extends Control
class_name MainMenu

@onready var play_button: Button = $CanvasLayer/UI/CenterContainer/VBoxContainer/PlayButton
@onready var stats_button: Button = $CanvasLayer/UI/CenterContainer/VBoxContainer/ViewStatsButton

func _ready():
	if game_manager.current_character:
		var path := game_manager.current_character.model_path

		# --- Play Button Logic ---
		if play_button:
			play_button.disabled = path == "" or path == null
			play_button.tooltip_text = "Please select a gender in Character Edit before playing." if play_button.disabled else ""
		else:
			push_error("PlayButton is missing!")

		# --- Stats Button Logic ---
		if stats_button:
			stats_button.disabled = path == "" or path == null
			stats_button.tooltip_text = "Please select a gender in Character Edit before viewing stats." if stats_button.disabled else ""
		else:
			push_error("StatsButton is missing!")
	else:
		push_error("Current character is missing!")

func _on_play_pressed():
	if play_button and not play_button.disabled:
		game_manager.go_to("game_world",true, 0.0, "res://assets/RPG-Actiongame-Environment-01.jpg")

func _on_edit_character_pressed():
	game_manager.go_to("character_customization")

func _on_view_stats_pressed():
	if stats_button and not stats_button.disabled:
		game_manager.go_to("stats")

func _on_log_out_pressed():
	game_manager.go_to("login")
