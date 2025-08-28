# res://core/game_manager.gd
extends Node
class_name GameManager

# === Runtime Data ===
var current_scene_path: String = ""
var current_character: Character = null
var page_paths : Dictionary = {
	"login": "res://ui/login_page/login_page.tscn",
	"main_menu": "res://ui/main_menu/main_menu.tscn",
	"game_world": "res://scenes/game_world/game_world.tscn",
	"character_customization": "res://scenes/character_customization/character_customization.tscn",
	"stats": "res://ui/stats_view/stats_view.tscn",
	"loading": "res://ui/loading_scene/loading.tscn",
	"settings": "res://ui/settings/settings_old.tscn",
	"inventory": "res://ui/stats_view/stats_view.tscn"
}

func _ready() -> void:
	if get_tree().current_scene:
		current_scene_path = get_tree().current_scene.scene_file_path

# --- Paths ---
func get_save_path(username: String) -> String:
	return "user://data/characters/%s.tres" % username

func _ensure_save_dir() -> void:
	var dir_path := "user://data/characters"
	if not DirAccess.dir_exists_absolute(dir_path):
		var err := DirAccess.make_dir_recursive_absolute(dir_path)
		if err != OK:
			push_error("Failed to create save directory: " + dir_path)

# === Game Flow ===
func start_new_game(username: String, password: String, is_new: bool, char_id := "") -> void:
	_ensure_save_dir()
	var save_path := get_save_path(username)

	if is_new:
		var new_char := Character.new()
		new_char.char_id = char_id
		new_char.username = username
		new_char.password = password
		new_char.last_position = Vector3(0, 0.5, 0)
		current_character = new_char

		var save_result := ResourceSaver.save(new_char, save_path)
		if save_result != OK:
			push_error("Failed to save new character to disk: " + save_path)
		else:
			print("Created and saved new character: %s at %s" % [char_id, save_path])
		go_to("character_customization")
	else:
		# Try user:// first (runtime saves), then res:// (dev fallback/templates)
		var loaded_res: Resource = null
		if ResourceLoader.exists(save_path):
			loaded_res = ResourceLoader.load(save_path)
		else:
			var dev_path := "res://data/characters/%s.tres" % username
			if ResourceLoader.exists(dev_path):
				loaded_res = ResourceLoader.load(dev_path)

		if loaded_res is Character:
			var loaded_char := loaded_res as Character
			if loaded_char.password == password:
				current_character = loaded_char
				print("Loaded character: %s" % loaded_char.char_id)
				go_to("main_menu")
			else:
				push_error("Password mismatch for existing character: " + username)
		else:
			push_error("No valid character file found for: " + username)

# === Save Logic ===
func save_player_position(position: Vector3) -> void:
	if current_character == null:
		push_warning("save_player_position: no current_character to write to.")
		return

	var safe_position := position
	if position.y < -1.0:
		push_warning("Character is falling — saving fallback position instead.")
		safe_position = Vector3(0, 0.5, 0)

	current_character.last_position = safe_position
	_ensure_save_dir()
	var file_path := get_save_path(current_character.username)
	var result := ResourceSaver.save(current_character, file_path)
	if result != OK:
		push_error("Failed to save character data to: " + file_path)

func save_player_position_from(player: Node3D) -> void:
	if player == null:
		push_warning("save_player_position_from: player is null.")
		return
	save_player_position(player.global_position)

func save_current_character() -> void:
	if current_character == null:
		push_warning("save_current_character: no current_character.")
		return
	_ensure_save_dir()
	var file_path := get_save_path(current_character.username)
	var result := ResourceSaver.save(current_character, file_path)
	if result != OK:
		push_error("Failed to save character to: " + file_path)

# === Quit Game ===
func quit_game() -> void:
	get_tree().quit()

# === Scene Navigation ===
func go_to(page_name: String, use_loading := false, wait_time : float = 0.0, bg_path := "res://assets/textures/3D World Image.jpg") -> void:
	if not page_paths.has(page_name):
		push_error("Unknown page name: " + page_name)
		return

	var path: String = page_paths[page_name]

	if use_loading:
		change_scene_with_loading_screen(path, wait_time, bg_path)
	else:
		change_scene(path)

# === Utility: Scene Switching ===
func change_scene(path: String) -> void:
	current_scene_path = path
	get_tree().change_scene_to_file(path)

# === Utility: Scene Switching with Loading page ===
func change_scene_with_loading_screen(target_path: String, wait_time: float = 0.0, background_path: String = "res://assets/textures/3D World Image.jpg") -> void:
	# Step 0: Remove the current scene (e.g., Main Menu)
	var current := get_tree().current_scene
	if current:
		get_tree().root.remove_child(current)
		current.queue_free()

	# Step 1: Instance the loading screen directly
	var loading_scene := preload("res://ui/loading_scene/loading.tscn").instantiate()
	get_tree().root.add_child(loading_scene)
	loading_scene.move_to_front()

	# Step 2: Optionally set background image
	if background_path != "":
		if loading_scene.has_node("BackgroundImage"):
			var bg_node := loading_scene.get_node("BackgroundImage")
			if bg_node is TextureRect:
				var tex := load(background_path)
				if tex is Texture2D:
					bg_node.texture = tex
				else:
					push_warning("Invalid texture at: " + background_path)
			else:
				push_warning("'BackgroundImage' is not a TextureRect.")
		else:
			push_warning("'BackgroundImage' node not found.")

	await get_tree().process_frame  # Ensure the loading screen is rendered

	# Step 3: Begin threaded load of target scene
	ResourceLoader.load_threaded_request(target_path)

	while ResourceLoader.load_threaded_get_status(target_path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame

	# Step 4: Optional delay
	if wait_time > 0.0:
		await get_tree().create_timer(wait_time).timeout

	# Step 5: Switch to the target scene
	var loaded := ResourceLoader.load_threaded_get(target_path)
	if loaded:
		current_scene_path = target_path
		get_tree().change_scene_to_packed(loaded)
	else:
		push_error("Failed to load scene: " + target_path)

	# Step 6: Clean up the loading screen
	if is_instance_valid(loading_scene):
		loading_scene.queue_free()
