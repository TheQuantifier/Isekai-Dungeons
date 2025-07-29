# res://ui/persistent_ui/persistent_ui.gd
extends CanvasLayer

func _on_quit_button_pressed() -> void:
	var current_scene = get_tree().current_scene

	# Only save position if in GameWorld
	if current_scene is GameWorld:
		var player = current_scene.get_node_or_null("Player")
		if player:
			game_manager.save_player_position(player.global_position)

	game_manager.quit_game()
