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
	var is_moving_forward = Input.is_action_pressed("move_forward")
	var is_moving_backward = Input.is_action_pressed("move_back")
	var is_crouching = Input.is_action_pressed("crouch")

	# Combine inputs
	if is_moving_forward:
		direction += transform.basis.z
	if is_moving_backward:
		direction -= transform.basis.z

	# Rotation input
	if Input.is_action_pressed("move_left"):
		rotate_y(turn_speed * delta)
	if Input.is_action_pressed("move_right"):
		rotate_y(-turn_speed * delta)

	direction.y = 0
	direction = direction.normalized()

	# Determine speed
	var speed := move_speed
	if is_crouching and (is_moving_forward or is_moving_backward):
		speed *= 0.5  # Crouch is slower
	if not is_on_floor():
		speed *= 0.5  # Air slows movement

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Jumping
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

		if is_crouching and is_moving_forward:
			anim_player.play("crouch_move_forward")
		elif is_crouching and is_moving_backward:
			anim_player.play("crouch_move_back")
		elif is_moving_forward:
			anim_player.play("run")
		elif is_moving_backward:
			anim_player.play("run_backward")
		else:
			anim_player.play("idle")
	else:
		if is_jumping:
			anim_player.play("jump", -1.0, 2.75)
