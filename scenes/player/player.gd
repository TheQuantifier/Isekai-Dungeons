# res://scenes/player/player.gd
extends CharacterBody3D

@export var move_speed: float = 8.0
@export var jump_velocity: float = 14.0
@export var turn_speed: float = 2.0  # Radians per second

@onready var gravity: float = 40
@onready var character_node: Node3D = $Character

var anim_player: AnimationPlayer
var is_jumping: bool = false

func _ready() -> void:
	load_model_from_character_data()

func load_model_from_character_data() -> void:
	# Clear any existing model
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

		# Get AnimationPlayer from model
		anim_player = model_instance.get_node_or_null("AnimationPlayer")
		if not anim_player:
			push_warning("No AnimationPlayer found in loaded model.")
	else:
		push_error("Failed to load model at path: " + model_path)

func _physics_process(delta: float) -> void:
	var direction = Vector3.ZERO
	var is_moving_forward = Input.is_action_pressed("move_forward")
	var is_moving_backward = Input.is_action_pressed("move_back")
	var is_crouching = Input.is_action_pressed("crouch")
	var is_sprinting = Input.is_action_pressed("sprint")

	if is_moving_forward:
		direction += transform.basis.z
	if is_moving_backward:
		direction -= transform.basis.z

	if Input.is_action_pressed("move_left"):
		rotate_y(turn_speed * delta)
	if Input.is_action_pressed("move_right"):
		rotate_y(-turn_speed * delta)

	direction.y = 0
	direction = direction.normalized()

	var speed := move_speed

	if is_sprinting and is_moving_forward and not is_crouching:
		speed *= 5.0  # Apply sprint multiplier

	if is_crouching and (is_moving_forward or is_moving_backward):
		speed *= 0.5
	if not is_on_floor():
		speed *= 0.5

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
		is_jumping = true
		if anim_player and anim_player.has_animation("jump"):
			anim_player.play("jump", -1.0, 2.75)

	move_and_slide()

	if anim_player and is_on_floor():
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
			if is_sprinting:
				anim_player.play("run", -1.0, 1.5)
			else:
				anim_player.play("run", -1.0, 1.0)
		elif is_moving_backward:
			if is_sprinting:
				anim_player.play("run_backward", -1.0, 2.0)
			else:
				anim_player.play("run_backward", -1.0, 1.0)
		else:
			anim_player.play("idle", -1.0, 1.0)
	elif anim_player and is_jumping:
		anim_player.play("jump", -1.0, 2.75)
