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
func start_new_game(username: String, password: String, is_new: bool) -> void:
	var save_path := "res://data/characters/%s.tres" % username

	if is_new:
		var new_char := Character.new()
		new_char.char_id = username
		new_char.password = password
		current_character = new_char
		var save_result := ResourceSaver.save(new_char, save_path)
		if save_result != OK:
			push_error("Failed to save new character to disk.")
		else:
			print("Created and saved new character: %s" % username)
		go_to_character_customization()
	else:
		if ResourceLoader.exists(save_path):
			var loaded_res := ResourceLoader.load(save_path)
			if loaded_res is Character:
				if loaded_res.password == password:
					current_character = loaded_res
					print("Loaded existing character: %s" % username)
					go_to_main_menu()
				else:
					push_error("Password mismatch for existing character: %s" % username)
			else:
				push_error("File exists but is not a valid Character resource.")
		else:
			push_error("No character file found for: %s" % username)

# === Scene Navigation ===
func go_to_login_page() -> void:
	change_scene("res://ui/login_page/login_page.tscn")

func go_to_main_menu() -> void:
	change_scene("res://ui/main_menu/main_menu.tscn")

func go_to_game_world() -> void:
	change_scene("res://ui/loading_scene/loading.tscn")

func go_to_character_customization() -> void:
	change_scene("res://scenes/character_customization/character_customization.tscn")

func go_to_view_stats() -> void:
	change_scene("res://ui/stats_view/stats_view.tscn")

func quit_game() -> void:
	get_tree().quit()

# === Utility: Scene Switching ===
func change_scene(path: String) -> void:
	current_scene_path = path
	get_tree().change_scene_to_file(path)
