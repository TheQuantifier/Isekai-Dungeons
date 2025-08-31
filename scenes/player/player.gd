# res://scenes/player/player.gd
extends CharacterBody3D

# --- Movement (land) ---
@export var move_speed: float = 8.0
@export var jump_velocity: float = 14.0
@export var turn_speed: float = 2.0  # radians/sec
@onready var gravity: float = 40.0

@onready var character_node: Node3D = $Character

# --- Movement (general / in-water) ---
@export var water_drag: float = 3.0          # horizontal damping in water
@export var water_speed_scale: float = 0.5   # slower horizontal move in water
@export var water_turn_scale: float = 0.5    # slower yaw in water

# --- Water surface model (manual only) ---
@export var water_surface_height: float = -5.0   # manual Y level of water

# Surface hold & bobbing
@export var enable_surface_hold: bool = true     # hold at surface while Jump held
@export var enable_bob: bool = true             # add sine bob while holding Jump

@export var bob_height: float = 0.2              # +/- meters (only if enable_bob)
@export var bob_speed: float = 0.5               # cycles/sec (only if enable_bob)
@export var bob_follow_accel: float = 12.0       # how fast we chase target
@export var bob_max_speed: float = 6.0           # clamp vertical speed
@export var water_sink_accel: float = 3.0        # gentle sink when NOT holding Jump
@export var max_sink_speed: float = 6.0          # cap downward speed when sinking
@export var surface_deadzone: float = 0.05       # no tweaks when this close to surface

# --- Animation state ---
var anim_player: AnimationPlayer
var is_jumping: bool = false

# --- Water state flags ---
var in_water: bool = false
var _was_in_water_last_frame: bool = false

# --- Bobbing phase ---
var _bob_t: float = 0.0

func _ready() -> void:
	load_model_from_character_data()

func load_model_from_character_data() -> void:
	for child in character_node.get_children():
		child.queue_free()

	var model_path: String = game_manager.current_character.model_path
	if not model_path or model_path == "":
		push_error("No model path defined in current character.")
		return

	var model_scene := load(model_path)
	if model_scene is PackedScene:
		var model_instance: Node3D = model_scene.instantiate()
		character_node.add_child(model_instance)
		anim_player = model_instance.get_node_or_null("AnimationPlayer")
		if not anim_player:
			push_warning("No AnimationPlayer found in loaded model.")
	else:
		push_error("Failed to load model at path: " + model_path)

func _physics_process(delta: float) -> void:
	var direction := Vector3.ZERO
	var is_moving_forward := Input.is_action_pressed("move_forward")
	var is_moving_backward := Input.is_action_pressed("move_back")
	var is_crouching := Input.is_action_pressed("crouch")
	var is_sprinting := Input.is_action_pressed("sprint")
	var jump_pressed := Input.is_action_just_pressed("jump")
	var jump_held := Input.is_action_pressed("jump")

	# --- Turning ---
	var turn_scale := (water_turn_scale if in_water else 1.0)
	if Input.is_action_pressed("move_left"):
		rotate_y(turn_speed * turn_scale * delta)
	if Input.is_action_pressed("move_right"):
		rotate_y(-turn_speed * turn_scale * delta)

	# --- Move direction (XZ) ---
	if is_moving_forward:
		direction += transform.basis.z
	if is_moving_backward:
		direction -= transform.basis.z
	direction.y = 0.0
	direction = direction.normalized()

	# --- Horizontal speed ---
	var speed := move_speed
	if is_sprinting and is_moving_forward and not is_crouching:
		speed *= 5.0
	if is_crouching and (is_moving_forward or is_moving_backward):
		speed *= 0.5
	if not is_on_floor() and not in_water:
		speed *= 0.5
	if in_water:
		speed *= water_speed_scale

	var target_vx := direction.x * speed
	var target_vz := direction.z * speed

	if in_water:
		velocity.x = move_toward(velocity.x, target_vx, water_drag * delta)
		velocity.z = move_toward(velocity.z, target_vz, water_drag * delta)
	else:
		velocity.x = target_vx
		velocity.z = target_vz

	# --- Vertical: land vs water ---
	if in_water:
		if not _was_in_water_last_frame:
			velocity.y = clamp(velocity.y, -bob_max_speed, bob_max_speed)

		var surface: float = water_surface_height

		if enable_surface_hold and jump_held:
			# Offset only if bobbing is enabled
			var offset: float = 0.0
			if enable_bob and bob_height > 0.0 and bob_speed > 0.0:
				_bob_t += delta
				offset = sin(TAU * bob_speed * _bob_t) * bob_height - 0.2

			var target_y: float = surface + offset
			var error: float = target_y - global_position.y

			# Deadzone to stop tiny oscillations
			if abs(error) <= surface_deadzone:
				velocity.y = move_toward(velocity.y, 0.0, bob_follow_accel * delta)
			else:
				var desired_vy: float = clamp(error * bob_follow_accel, -bob_max_speed, bob_max_speed)
				velocity.y = move_toward(velocity.y, desired_vy, bob_follow_accel * delta)
		else:
			# Not holding Jump: sink gently
			velocity.y = max(velocity.y - water_sink_accel * delta, -max_sink_speed)
	else:
		# Land gravity / jump
		if not is_on_floor():
			velocity.y -= gravity * delta
		if jump_pressed and is_on_floor():
			velocity.y = jump_velocity
			is_jumping = true
			if anim_player and anim_player.has_animation("jump"):
				anim_player.play("jump", -1.0, 2.75)

	move_and_slide()
	_was_in_water_last_frame = in_water

	# --- Animations (land only) ---
	if anim_player and is_on_floor() and not in_water:
		if is_jumping:
			is_jumping = false

		if is_crouching:
			if is_moving_forward:
				anim_player.play("crouch_move_forward", -1.0, 1.0)
			elif is_moving_backward:
				anim_player.play("crouch_move_back", -1.0, 1.0)
			else:
				anim_player.play("crouch_idle", -1.0, 1.0)
		elif is_moving_forward:
			anim_player.play("run", -1.0, (1.5 if is_sprinting else 1.0))
		elif is_moving_backward:
			anim_player.play("run_backward", -1.0, (2.0 if is_sprinting else 1.0))
		else:
			anim_player.play("idle", -1.0, 1.0)
	elif anim_player and is_jumping:
		anim_player.play("jump", -1.0, 2.75)

# --- Hooks from UnderwaterZone ---
func set_in_water(value: bool) -> void:
	if value and not in_water:
		_bob_t = 0.0
	in_water = value
