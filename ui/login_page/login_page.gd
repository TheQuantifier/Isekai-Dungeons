extends Control

@onready var username_field: LineEdit = $CenterContainer/VBoxContainer/UsernameField
@onready var password_field: LineEdit = $CenterContainer/VBoxContainer/PasswordField
@onready var start_button: Button = $CenterContainer/VBoxContainer/StartGameButton

@onready var wrong_password_popup_overlay: Control = $WrongPasswordPopupOverlay
@onready var wrong_password_popup: Panel = $WrongPasswordPopupOverlay/WrongPasswordPopup

@onready var create_character_dialog_overlay: Control = $CreateCharacterDialogOverlay
@onready var create_character_dialog: Panel = $CreateCharacterDialogOverlay/CreateCharacterDialog

var is_new := false

func _ready() -> void:
	start_button.disabled = true
	username_field.grab_focus()

	# Hide both overlays at startup
	hide_overlay(wrong_password_popup_overlay)
	hide_overlay(create_character_dialog_overlay)

	# Ensure both overlays block input and appear above everything
	wrong_password_popup_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	create_character_dialog_overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	wrong_password_popup_overlay.z_index = 100
	create_character_dialog_overlay.z_index = 100

func get_trimmed_credentials() -> Dictionary:
	return {
		"username": username_field.text.strip_edges(),
		"password": password_field.text.strip_edges()
	}

func show_overlay(overlay: Control) -> void:
	start_button.disabled = true
	overlay.move_to_front()
	overlay.visible = true

func hide_overlay(overlay: Control) -> void:
	overlay.visible = false

func _on_username_field_text_changed(_new_text: String) -> void:
	_check_fields()

func _on_password_field_text_changed(_new_text: String) -> void:
	_check_fields()

func _check_fields() -> void:
	var creds := get_trimmed_credentials()
	start_button.disabled = creds.username.is_empty() or creds.password.is_empty()

func _on_start_game_button_pressed() -> void:
	var creds := get_trimmed_credentials()
	var save_path := "res://data/characters/%s.tres" % creds.username

	if ResourceLoader.exists(save_path):
		var loaded_res := ResourceLoader.load(save_path)
		if not loaded_res:
			push_error("Failed to load character file.")
			return

		if loaded_res is Character:
			if loaded_res.password == creds.password:
				game_manager.start_new_game(creds.username, creds.password, false)
			else:
				password_field.clear()
				password_field.grab_focus()
				show_overlay(wrong_password_popup_overlay)
		else:
			push_error("Character file found but is not a valid Character resource.")
	else:
		show_overlay(create_character_dialog_overlay)

func _on_create_character_dialog_yes_pressed() -> void:
	is_new = true
	var creds := get_trimmed_credentials()
	hide_overlay(create_character_dialog_overlay)
	start_button.disabled = false
	game_manager.start_new_game(creds.username, creds.password, true)

func _on_create_character_dialog_no_pressed() -> void:
	is_new = false
	hide_overlay(create_character_dialog_overlay)
	start_button.disabled = false

func _on_wrong_password_ok_button_pressed() -> void:
	hide_overlay(wrong_password_popup_overlay)
	_check_fields()  # Re-check fields to re-enable Start button if applicable

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and not start_button.disabled:
		_on_start_game_button_pressed()
