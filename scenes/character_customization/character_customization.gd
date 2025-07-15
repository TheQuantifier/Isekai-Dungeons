extends Node3D

@onready var model_holder: Node3D = $ModelHolder
@onready var camera: Camera3D = $ModelHolder/Camera3D
@onready var light: DirectionalLight3D = $ModelHolder/DirectionalLight3D
@onready var confirm_button: Button = $UI/VBoxContainer/ConfirmButton

@export var model_vertical_offset: float = 0.5
@export var model_horizontal_offset: float = 0.0

const MALE_MODEL_PATH: String = "res://assets/character_models/scenes/male/y_bot.tscn"
const FEMALE_MODEL_PATH: String = "res://assets/character_models/scenes/female/x_bot.tscn"
const ROTATION_SPEED := 1.5  # Radians per second

var current_model: Node3D

func _ready() -> void:
	model_holder.transform.origin = Vector3(model_horizontal_offset, model_vertical_offset, 0)
	position_camera_and_light()

	# Disable Confirm button initially
	confirm_button.disabled = true

	# Set default gender and model only if gender not already chosen
	if game_manager.current_character:
		if game_manager.current_character.gender == "":
			game_manager.current_character.gender = "male"
			game_manager.current_character.model_path = MALE_MODEL_PATH
		_load_gender_model()
	else:
		push_error("No current character loaded in game_manager.")

func _process(delta: float) -> void:
	if current_model:
		if Input.is_action_pressed("move_left"):
			current_model.rotate_y(-ROTATION_SPEED * delta)
		elif Input.is_action_pressed("move_right"):
			current_model.rotate_y(ROTATION_SPEED * delta)

func position_camera_and_light() -> void:
	camera.transform.origin = Vector3(0, 2, 2)
	camera.look_at(Vector3(0, 1.2, 0), Vector3.UP)
	light.rotation_degrees = Vector3(-45, 45, 0)

func load_model(path: String) -> void:
	if current_model:
		current_model.queue_free()

	var model_scene = load(path)
	if model_scene is PackedScene:
		current_model = model_scene.instantiate()
		model_holder.add_child(current_model)
	else:
		push_error("Failed to load model at: " + path)

func _load_gender_model() -> void:
	if game_manager.current_character.gender == "male":
		load_model(MALE_MODEL_PATH)
	elif game_manager.current_character.gender == "female":
		load_model(FEMALE_MODEL_PATH)

func _on_male_button_pressed() -> void:
	load_model(MALE_MODEL_PATH)
	if game_manager.current_character:
		game_manager.current_character.gender = "male"
		game_manager.current_character.model_path = MALE_MODEL_PATH
		confirm_button.disabled = false

func _on_female_button_pressed() -> void:
	load_model(FEMALE_MODEL_PATH)
	if game_manager.current_character:
		game_manager.current_character.gender = "female"
		game_manager.current_character.model_path = FEMALE_MODEL_PATH
		confirm_button.disabled = false

func _on_confirm_button_pressed() -> void:
	if game_manager.current_character:
		var save_path := "res://data/characters/%s.tres" % game_manager.current_character.char_id
		var result := ResourceSaver.save(game_manager.current_character, save_path)
		if result != OK:
			push_error("Failed to save character.")
		else:
			print("Character saved with gender: ", game_manager.current_character.gender)

	confirm_button.disabled = true  # Gray out again after confirm

func _on_main_menu_pressed() -> void:
	game_manager.go_to_main_menu()
