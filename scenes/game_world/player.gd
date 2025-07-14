# res://scenes/player/player.gd
extends CharacterBody3D

@export var move_speed: float = 8.0
@export var jump_velocity: float = 14.0
@export var turn_speed: float = 2.0  # Radians per second

@onready var gravity: float = 40
@onready var anim_player = $Running/AnimationPlayer  # Adjust path as needed

var is_jumping: bool = false

func _physics_process(delta: float) -> void:
	var direction = Vector3.ZERO
	var is_moving_forward = false
	var is_moving_backward = false

	# Movement input
	if Input.is_action_pressed("move_forward"):
		direction += transform.basis.z
		is_moving_forward = true
	if Input.is_action_pressed("move_back"):
		direction -= transform.basis.z
		is_moving_backward = true

	# Rotation input
	if Input.is_action_pressed("move_left"):
		rotate_y(turn_speed * delta)
	if Input.is_action_pressed("move_right"):
		rotate_y(-turn_speed * delta)

	direction.y = 0
	direction = direction.normalized()

	# Apply horizontal velocity (reduced if airborne)
	if is_on_floor():
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		velocity.x = direction.x * (move_speed * 0.5)
		velocity.z = direction.z * (move_speed * 0.5)

	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Jump input
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
		is_jumping = true
		if anim_player.has_animation("jump"):
			anim_player.play("jump", -1.0, 2.75)

	move_and_slide()

	# Animation Logic
	if is_on_floor():
		if is_jumping:
			is_jumping = false  # Landed

		if is_moving_forward:
			if anim_player.current_animation != "run":
				anim_player.play("run")
		elif is_moving_backward:
			if anim_player.current_animation != "run_backward":
				anim_player.play("run_backward")
		else:
			if anim_player.current_animation != "idle":
				anim_player.play("idle")
	else:
		if is_jumping and anim_player.current_animation != "jump":
			anim_player.play("jump", -1.0, 2.75)
