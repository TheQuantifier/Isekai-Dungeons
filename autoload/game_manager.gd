# res://core/game_manager.gd
extends Node
class_name GameManager

# === Runtime Data ===
var current_scene_path: String = ""
var current_character: Character = null

func _ready() -> void:
	if get_tree().current_scene:
		current_scene_path = get_tree().current_scene.scene_file_path

# === Game Flow ===
func start_new_game(username: String) -> void:
	var save_path := "res://data/characters/%s.tres" % username

	if ResourceLoader.exists(save_path):
		var loaded_res := ResourceLoader.load(save_path)
		if loaded_res is Character:
			current_character = loaded_res
			print("Loaded existing character: %s" % username)
		else:
			push_error("File exists but is not a valid Character resource.")
	else:
		var new_char := Character.new()
		new_char.char_id = username
		current_character = new_char
		var save_result := ResourceSaver.save(new_char, save_path)
		if save_result != OK:
			push_error("Failed to save new character to disk.")
		else:
			print("Created and saved new character: %s" % username)

	change_scene("res://ui/character_hub/character_hub.tscn")

func return_to_main_menu() -> void:
	change_scene("res://ui/main_menu/main_menu.tscn")

func quit_game() -> void:
	get_tree().quit()

# === Scene Switching Utility ===
func change_scene(path: String) -> void:
	current_scene_path = path
	get_tree().change_scene_to_file(path)
