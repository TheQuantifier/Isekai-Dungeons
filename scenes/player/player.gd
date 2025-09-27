extends CharacterBody3D

@export var settings: PlayerSettings   # link your .tres in the inspector

@onready var character_node: Node3D = $Character
@onready var camera_rig: CameraRig = $CameraRig

# Put the imported character model on this Visibility Layer (0-based index).
# CameraRig can then hide/show this layer in 1P/3P via its cull_mask toggle.
@export var character_visibility_layer_index: int = 1   # Layer 2 by default

# -------------------------------------------------------------------
# Animation state
# -------------------------------------------------------------------
var anim_player: AnimationPlayer
var is_jumping: bool = false

# -------------------------------------------------------------------
# Water state
# -------------------------------------------------------------------
var in_water: bool = false
var _was_in_water_last_frame: bool = false

# -------------------------------------------------------------------
# Bobbing control
# -------------------------------------------------------------------
var _bob_t: float = 0.0
const WATER_STILL_EPS: float = 0.2
const LAND_STILL_EPS: float = 0.05

# -------------------------------------------------------------------
# Ground stick helpers
# -------------------------------------------------------------------
@export var stick_force: float = 2.0
@export var floor_snap_len: float = 1.5
@export_range(0.0, 89.0) var floor_max_angle_deg: float = 50.0

# -------------------------------------------------------------------
# Grounded cache
# -------------------------------------------------------------------
var _grounded_cached: bool = false

# -------------------------------------------------------------------
# Lifecycle
# -------------------------------------------------------------------
func _ready() -> void:
	if settings == null:
		push_warning("Player: No PlayerSettings assigned. Using defaults.")
		settings = PlayerSettings.new()
	load_model_from_character_data()

	floor_snap_length = floor_snap_len
	floor_max_angle = deg_to_rad(floor_max_angle_deg)
	motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED

	# CameraRig initialization (child of Player)
	if is_instance_valid(camera_rig):
		camera_rig.world_attached = false
		camera_rig.configure(self)
	else:
		push_warning("Player: CameraRig child not found.")

# -------------------------------------------------------------------
# Model loading
# -------------------------------------------------------------------
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

		# --- Put the model on a dedicated Visibility Layer so the camera can hide it in 1P ---
		var layer_idx := character_visibility_layer_index
		if is_instance_valid(camera_rig) and camera_rig.head_visibility_layer >= 0:
			# Keep in sync with the CameraRig’s configured hide layer if present
			layer_idx = camera_rig.head_visibility_layer
		_set_visibility_layer_recursive(model_instance, layer_idx)

		anim_player = model_instance.get_node_or_null("AnimationPlayer")
		if anim_player == null:
			push_warning("No AnimationPlayer found in loaded model.")
	else:
		push_error("Failed to load model at path: " + model_path)

# Recursively set the Visibility Layers of any renderers (MeshInstance3D/SkinnedMeshInstance3D/etc.)
func _set_visibility_layer_recursive(node: Node, layer_index: int) -> void:
	var bit := 1 << layer_index
	if node is GeometryInstance3D:
		var gi := node as GeometryInstance3D
		# Replace with exactly this layer; switch to (gi.layers |= bit) if you prefer additive.
		gi.layers = bit
	for c in node.get_children():
		_set_visibility_layer_recursive(c, layer_index)

# -------------------------------------------------------------------
# Physics
# -------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	# --- Input states ---
	var direction: Vector3 = Vector3.ZERO
	var is_moving_forward := Input.is_action_pressed("move_forward")
	var is_moving_backward := Input.is_action_pressed("move_back")
	var is_turning_left := Input.is_action_pressed("move_left")     # rotate body
	var is_turning_right := Input.is_action_pressed("move_right")   # rotate body
	var is_crouching := Input.is_action_pressed("crouch")
	var is_sprinting := Input.is_action_pressed("sprint")
	var jump_pressed := Input.is_action_just_pressed("jump")
	var jump_held := Input.is_action_pressed("jump")

	# IMPORTANT: query floor state BEFORE physics step
	var was_on_floor := is_on_floor()

	# --- Turn CHARACTER (camera will auto-center in rig when no look input) ---
	var turn_rate := (settings.water_turn_speed if in_water else settings.turn_speed) # radians/sec
	var turn_step := 0.0
	if is_turning_left:
		turn_step += turn_rate * delta
	if is_turning_right:
		turn_step -= turn_rate * delta
	if turn_step != 0.0:
		rotation.y = wrapf(rotation.y + turn_step, -PI, PI)

	# --- Build forward vector from CURRENT PLAYER facing (XZ only) ---
	var fwd := transform.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()

	# --- Movement (no strafing; forward/back relative to body) ---
	if is_moving_forward:
		direction += fwd
	if is_moving_backward:
		direction -= fwd

	# Normalize planar move vector
	if direction != Vector3.ZERO:
		direction = direction.normalized()

	# --- Speed selection ---
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

	# --- Horizontal velocity ---
	if was_on_floor and not in_water:
		var flat_vel := (direction * speed).slide(get_floor_normal())
		velocity.x = flat_vel.x
		velocity.z = flat_vel.z
	else:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed

	# --- Vertical velocity ---
	if in_water:
		_handle_water_vertical(delta, jump_held)
	else:
		_handle_land_vertical(delta, was_on_floor, jump_pressed)

	# --- Apply movement ---
	move_and_slide()

	# Floor snap
	if velocity.y <= 0.0 and not in_water:
		apply_floor_snap()

	# Cache grounded
	_grounded_cached = is_on_floor()

	# Animations
	var now_on_floor := _grounded_cached
	_was_in_water_last_frame = in_water
	_handle_animations(is_moving_forward, Input.is_action_pressed("move_back"), is_crouching, is_sprinting, now_on_floor)

# -------------------------------------------------------------------
# Vertical helpers
# -------------------------------------------------------------------
func _handle_water_vertical(delta: float, jump_held: bool) -> void:
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

func _handle_land_vertical(delta: float, was_on_floor: bool, jump_pressed: bool) -> void:
	if not was_on_floor:
		velocity.y -= settings.gravity * delta
	else:
		velocity.y = -stick_force

	if jump_pressed and was_on_floor:
		velocity.y = settings.jump_velocity
		is_jumping = true
		var planar_speed := Vector2(velocity.x, velocity.z).length()
		if planar_speed <= LAND_STILL_EPS:
			_play("jump_stat", settings.anim_jump_stat)
		else:
			_play("jump", settings.anim_jump)

# -------------------------------------------------------------------
# Animations
# -------------------------------------------------------------------
func _handle_animations(is_moving_forward: bool, is_moving_backward: bool, is_crouching: bool, is_sprinting: bool, now_on_floor: bool) -> void:
	if anim_player == null:
		return

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

# -------------------------------------------------------------------
# Hooks from UnderwaterZone
# -------------------------------------------------------------------
func set_in_water(value: bool) -> void:
	if value and not in_water:
		_bob_t = 0.0
	in_water = value

# -------------------------------------------------------------------
# Camera/View API
# -------------------------------------------------------------------
func set_first_person(enable: bool) -> void:
	if is_instance_valid(camera_rig) and camera_rig.has_method("set_first_person"):
		camera_rig.set_first_person(enable)

# Helpers that define "forward" for others (like the CameraRig)
func get_forward_yaw() -> float:
	return rotation.y

func get_forward_basis() -> Basis:
	return global_transform.basis

# -------------------------------------------------------------------
# Animation helper
# -------------------------------------------------------------------
func _play(anim_name: String, rate: float, _smoothness: float = settings.anim_smoothness) -> void:
	if anim_player == null:
		return
	if anim_player.current_animation != anim_name:
		anim_player.play(anim_name, _smoothness, rate)
	else:
		anim_player.speed_scale = rate

# -------------------------------------------------------------------
# Save Helper
# -------------------------------------------------------------------
func can_be_safely_saved() -> bool:
	return _grounded_cached and not in_water
