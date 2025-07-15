extends Control

@onready var username_field = $CenterContainer/VBoxContainer/UsernameField
@onready var start_button = $CenterContainer/VBoxContainer/StartGameButton

func _ready() -> void:
	start_button.disabled = true  # Start disabled

func _on_username_field_text_changed(new_text: String) -> void:
	start_button.disabled = new_text.strip_edges() == ""

func _on_start_game_button_pressed() -> void:
	var username = username_field.text.strip_edges()
	if username != "":
		game_manager.start_new_game(username)
