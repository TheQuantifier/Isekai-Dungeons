# res://scenes/player/player.gd
extends CharacterBody3D

@export var settings: PlayerSettings   # link your .tres in the inspector

@onready var character_node: Node3D = $Character

# --- Animation state ---
var anim_player: AnimationPlayer
var is_jumping: bool = false

# --- Water state ---
var in_water: bool = false
var _was_in_water_last_frame: bool = false

# --- Bobbing phase ---
var _bob_t: float = 0.0

# Small speed threshold to consider the player "still" in water
const WATER_STILL_EPS: float = 0.2

func _ready() -> void:
	if settings == null:
		push_warning("Player: No PlayerSettings assigned. Using defaults.")
		settings = PlayerSettings.new()
	load_model_from_character_data()

func load_model_from_character_data() -> void:
	for child in character_node.get_children():
		child.queue_free()

	var model_path: String = game_manager.current_character.model_path
	if model_path.is_empty():
		push_error("No model path defined in current character.")
		return

	var model_scene := load(model_path)
	if model_scene is PackedScene:
		var model_instance: Node3D = model_scene.instantiate()
		character_node.add_child(model_instance)

		anim_player = model_instance.get_node_or_null("AnimationPlayer")
		if anim_player == null:
			push_warning("No AnimationPlayer found in loaded model.")
	else:
		push_error("Failed to load model at path: " + model_path)

func _physics_process(delta: float) -> void:
	var direction: Vector3 = Vector3.ZERO
	var is_moving_forward := Input.is_action_pressed("move_forward")
	var is_moving_backward := Input.is_action_pressed("move_back")
	var is_crouching := Input.is_action_pressed("crouch")
	var is_sprinting := Input.is_action_pressed("sprint")
	var jump_pressed := Input.is_action_just_pressed("jump")
	var jump_held := Input.is_action_pressed("jump")

	# IMPORTANT: query floor state BEFORE physics step for jump/air control
	var was_on_floor := is_on_floor()

	# --- Turning ---
	var current_turn_speed: float = settings.water_turn_speed if in_water else settings.turn_speed
	if Input.is_action_pressed("move_left"):
		rotate_y(current_turn_speed * delta)
	if Input.is_action_pressed("move_right"):
		rotate_y(-current_turn_speed * delta)

	# --- Move direction (XZ) ---
	if is_moving_forward:
		direction += transform.basis.z
	if is_moving_backward:
		direction -= transform.basis.z
	direction.y = 0.0
	direction = direction.normalized()

	# --- Horizontal speed ---
	var speed: float = settings.move_speed
	if is_sprinting and is_moving_forward and not is_crouching:
		speed = settings.sprint_speed
	if is_crouching and (is_moving_forward or is_moving_backward):
		speed = settings.crouch_speed
	if not was_on_floor and not in_water:
		speed = settings.airborne_speed
	if in_water:
		if is_sprinting and is_moving_forward and not is_crouching:
			speed = settings.water_sprint_speed
		else:
			speed = settings.water_speed

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	
	# --- Vertical: land vs water ---
	if in_water:
		if not _was_in_water_last_frame:
			velocity.y = clamp(velocity.y, -settings.bob_max_speed, settings.bob_max_speed)

		var surface: float = settings.water_surface_height + settings.surface_offset

		if settings.enable_surface_hold and jump_held:
			var offset: float = 0.0
			if settings.enable_bob and settings.bob_height > 0.0 and settings.bob_speed > 0.0:
				_bob_t += delta
				offset = sin(TAU * settings.bob_speed * _bob_t) * settings.bob_height

			var target_y: float = surface + offset
			var error: float = target_y - global_position.y

			var desired_vy: float = clamp(error * settings.bob_follow_accel, -settings.bob_max_speed, settings.bob_max_speed)
			velocity.y = move_toward(velocity.y, desired_vy, settings.bob_follow_accel * delta)
		else:
			velocity.y = max(velocity.y - settings.water_sink_accel * delta, -settings.max_sink_speed)
	else:
		if not was_on_floor:
			velocity.y -= settings.gravity * delta
		if jump_pressed and was_on_floor:
			velocity.y = settings.jump_velocity
			is_jumping = true
			_play("jump", settings.anim_jump)

	move_and_slide()

	# For animation decisions, use floor state AFTER physics step
	var now_on_floor := is_on_floor()
	_was_in_water_last_frame = in_water

	# --- Animations ---
	if anim_player:
		if in_water:
			var planar_speed: float = Vector2(velocity.x, velocity.z).length()
			var moving_horizontally: bool = is_moving_forward or is_moving_backward
			var standing_still_in_water: bool = (not moving_horizontally) and (planar_speed <= WATER_STILL_EPS)

			if standing_still_in_water:
				_play("treading", settings.anim_treading)
			elif is_sprinting and is_moving_forward and not is_crouching:
				_play("swimming", settings.anim_swim_sprint)
			else:
				_play("swimming", settings.anim_swim)
		elif is_jumping and not now_on_floor:
			pass
		elif now_on_floor:
			if is_jumping:
				is_jumping = false

			if is_crouching:
				if is_moving_forward:
					_play("crouch_move_forward", settings.anim_crouch_run)
				elif is_moving_backward:
					_play("crouch_move_back", settings.anim_crouch_run_backward)
				else:
					_play("crouch_idle", settings.anim_crouch_idle)
			elif is_moving_forward:
				_play("run", (settings.anim_sprint if is_sprinting else settings.anim_run), (-1.0 if is_sprinting else settings.anim_smoothness))
			elif is_moving_backward:
				_play("run_backward", (settings.anim_sprint_backward if is_sprinting else settings.anim_run_backward))
			else:
				_play("idle", settings.anim_idle)

# --- Hooks from UnderwaterZone ---
func set_in_water(value: bool) -> void:
	if value and not in_water:
		_bob_t = 0.0
	in_water = value

# --- Internal helper: only play if switching animations ---
func _play(anim_name: String, rate: float, _smoothness: float = settings.anim_smoothness) -> void:
	if anim_player == null:
		return
	if anim_player.current_animation != anim_name:
		anim_player.play(anim_name, _smoothness, rate)
	else:
		anim_player.speed_scale = rate
