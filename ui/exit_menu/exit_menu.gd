extends CanvasLayer


func _on_main_menu_button_pressed() -> void:
	get_tree().paused = false
	game_manager.go_to("main_menu")

func _on_settings_button_pressed() -> void:
	get_tree().paused = false
	game_manager.go_to("settings")

func _on_quit_button_pressed() -> void:
	get_tree().paused = false
	game_manager.quit_game()

func _on_closs_button_pressed() -> void:
	get_tree().paused = false
	self.visible = false;

func _unhandled_input(event: InputEvent) -> void:
		
	if event.is_action_pressed("ui_cancel"):
		var is_open = not self.visible
		self.visible = is_open
		get_tree().paused = is_open
