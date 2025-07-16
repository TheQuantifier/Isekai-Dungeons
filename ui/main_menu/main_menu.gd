extends Control
class_name MainMenu

@onready var play_button: Button = $CanvasLayer/UI/CenterContainer/VBoxContainer/PlayButton
@onready var stats_button: Button = $CanvasLayer/UI/CenterContainer/VBoxContainer/ViewStatsButton  # ✅ Added this line

func _ready():
	if game_manager.current_character:
		var path := game_manager.current_character.model_path

		# --- Play Button Logic ---
		if play_button:
			if path == "" or path == null:
				play_button.disabled = true
				play_button.tooltip_text = "Please select a gender in Character Edit before playing."
			else:
				play_button.disabled = false
				play_button.tooltip_text = ""
		else:
			push_error("PlayButton is missing!")

		# --- Stats Button Logic ---
		if stats_button:
			if path == "" or path == null:
				stats_button.disabled = true
				stats_button.tooltip_text = "Please select a gender in Character Edit before viewing stats."
			else:
				stats_button.disabled = false
				stats_button.tooltip_text = ""
		else:
			push_error("StatsButton is missing!")
	else:
		push_error("Current character is missing!")

func _on_play_pressed():
	if play_button and not play_button.disabled:
		game_manager.go_to_game_world()

func _on_edit_character_pressed():
	game_manager.go_to_character_customization()

func _on_view_stats_pressed():
	if stats_button and not stats_button.disabled:
		game_manager.go_to_view_stats()

func _on_log_out_pressed():
	game_manager.go_to_login_page()
