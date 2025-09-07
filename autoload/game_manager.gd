# res://core/game_manager.gd
extends Node
class_name GameManager

# -------------------------------------------------------------------
# Runtime Data
# -------------------------------------------------------------------
var current_scene_path: String = ""       # Path of the currently active scene
var current_character: Character = null   # Currently active/loaded character

# -------------------------------------------------------------------
# Lifecycle
# -------------------------------------------------------------------
func _ready() -> void:
	# Track the starting scene path when the game boots
	if get_tree().current_scene:
		current_scene_path = get_tree().current_scene.scene_file_path

# -------------------------------------------------------------------
# Save File Paths
# -------------------------------------------------------------------
func get_save_path(username: String) -> String:
	# User-specific save file path (stored in user:// sandbox)
	return "user://data/characters/%s.tres" % username

func _ensure_save_dir() -> void:
	# Create save directory if it doesn’t exist
	var dir_path := "user://data/characters"
	if not DirAccess.dir_exists_absolute(dir_path):
		var err := DirAccess.make_dir_recursive_absolute(dir_path)
		if err != OK:
			push_error("Failed to create save directory: " + dir_path)

# -------------------------------------------------------------------
# Game Flow: Starting or Loading Characters
# -------------------------------------------------------------------
func start_new_game(username: String, password: String, is_new: bool, char_id := "") -> void:
	_ensure_save_dir()
	var save_path := get_save_path(username)

	if is_new:
		# --- Create new character resource ---
		var new_char := Character.new()
		new_char.char_id = char_id
		new_char.username = username
		new_char.password = password
		new_char.last_position = Vector3(0, 1, 0)
		current_character = new_char

		# Save character resource to disk
		var save_result := ResourceSaver.save(new_char, save_path)
		if save_result != OK:
			push_error("Failed to save new character to disk: " + save_path)
		else:
			print("Created and saved new character: %s at %s" % [char_id, save_path])

		# Go to customization flow for fresh characters
		go_to(Page.CHARACTER_CUSTOMIZATION)
	else:
		# --- Load existing character resource ---
		var loaded_res: Resource = null
		if ResourceLoader.exists(save_path):
			loaded_res = ResourceLoader.load(save_path)
		else:
			# Development fallback path
			var dev_path := "res://data/characters/%s.tres" % username
			if ResourceLoader.exists(dev_path):
				loaded_res = ResourceLoader.load(dev_path)

		if loaded_res is Character:
			var loaded_char := loaded_res as Character
			# Simple password check
			if loaded_char.password == password:
				current_character = loaded_char
				print("Loaded character: %s" % loaded_char.char_id)
				go_to(Page.MAIN_MENU)
			else:
				push_error("Password mismatch for existing character: " + username)
		else:
			push_error("No valid character file found for: " + username)

# -------------------------------------------------------------------
# Save Logic
# -------------------------------------------------------------------
func save_position(position: Vector3) -> void:
	# Writes the given position to the current character and persists it.
	# Assumes the caller has already decided it's safe to save this position.
	if current_character == null:
		push_warning("save_position: no current_character to write to.")
		return

	current_character.last_position = position
	_ensure_save_dir()

	var file_path := get_save_path(current_character.username)
	var result := ResourceSaver.save(current_character, file_path)
	if result != OK:
		push_error("Failed to save character data to: " + file_path)

func save_position_from(player: Node3D) -> void:
	# Saves ONLY if the player node is valid, inside the tree, and reports safe.
	# Requires Player to implement: func can_be_safely_saved() -> bool
	if player == null or not is_instance_valid(player):
		# Player missing or freed; nothing to do.
		return
	if not player.is_inside_tree():
		# Likely during scene teardown; skip to avoid get_global_transform assertions.
		return
	if not player.has_method("can_be_safely_saved"):
		# Conservative: don't guess if helper is missing.
		return

	if player.can_be_safely_saved():
		save_position(player.global_position)
	# else: unsafe (in water / mid-air) -> skip saving to preserve last good land position.

func save_character() -> void:
	# Save the full character resource (not just position)
	if current_character == null:
		push_warning("save_character: no current_character.")
		return

	_ensure_save_dir()
	var file_path := get_save_path(current_character.username)
	var result := ResourceSaver.save(current_character, file_path)
	if result != OK:
		push_error("Failed to save character to: " + file_path)

# -------------------------------------------------------------------
# Quit Game
# -------------------------------------------------------------------
func quit_game() -> void:
	get_tree().quit()

# -------------------------------------------------------------------
# Scene Navigation
# -------------------------------------------------------------------
func go_to(path: String, use_loading := false, wait_time: float = 0.0, bg_path := "res://assets/textures/3D World Image.jpg") -> void:
	# Switch scenes (with optional loading screen)
	if path == "" or not path.begins_with("res://"):
		push_error("go_to: expected a res:// path (use Page constants). Got: " + path)
		return

	if use_loading:
		change_scene_with_loading_screen(path, wait_time, bg_path)
	else:
		change_scene(path)

func change_scene(path: String) -> void:
	# Directly switch scene
	current_scene_path = path
	get_tree().change_scene_to_file(path)

func change_scene_with_loading_screen(
	target_path: String,
	wait_time: float = 0.0,
	background_path: String = "res://assets/textures/3D World Image.jpg"
) -> void:
	# Swap out current scene for loading screen while new scene loads
	var current := get_tree().current_scene
	if current:
		get_tree().root.remove_child(current)
		current.queue_free()

	var loading_scene := preload("res://ui/loading_scene/loading.tscn").instantiate()
	get_tree().root.add_child(loading_scene)
	loading_scene.move_to_front()

	# Configure loading background if node exists
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

	# Allow UI to render before loading
	await get_tree().process_frame

	# Threaded resource load
	ResourceLoader.load_threaded_request(target_path)
	while ResourceLoader.load_threaded_get_status(target_path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame

	# Optional artificial wait
	if wait_time > 0.0:
		await get_tree().create_timer(wait_time).timeout

	# Apply loaded scene
	var loaded := ResourceLoader.load_threaded_get(target_path)
	if loaded:
		current_scene_path = target_path
		get_tree().change_scene_to_packed(loaded)
	else:
		push_error("Failed to load scene: " + target_path)

	# Cleanup loading scene
	if is_instance_valid(loading_scene):
		loading_scene.queue_free()
