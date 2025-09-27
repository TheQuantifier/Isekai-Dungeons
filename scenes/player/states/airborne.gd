extends PlayerState

func physics_update(delta: float) -> void:
	if owner.in_water:
		owner.change_state(owner.st_swimming)
		return

	var was_on_floor := owner.is_on_floor()

	# Input (allow turning mid-air to keep facing snappy)
	var is_turning_left := Input.is_action_pressed("move_left")
	var is_turning_right := Input.is_action_pressed("move_right")
	var is_moving_forward := Input.is_action_pressed("move_forward")
	var is_moving_backward := Input.is_action_pressed("move_back")
	var is_strafe_left := Input.is_action_pressed("strafe_left")
	var is_strafe_right := Input.is_action_pressed("strafe_right")
	var is_crouching := Input.is_action_pressed("crouch")
	var is_sprinting := Input.is_action_pressed("sprint")

	var turn_rate : float = owner.settings.turn_speed
	if is_turning_left:
		owner.rotate_y(turn_rate * delta)
	if is_turning_right:
		owner.rotate_y(-turn_rate * delta)

	var axes : Dictionary = owner.compute_local_axes()
	var fwd: Vector3 = axes.fwd
	var right: Vector3 = axes.right

	var direction := Vector3.ZERO
	if is_moving_forward:  direction += fwd
	if is_moving_backward: direction -= fwd
	if is_strafe_right:    direction -= right
	if is_strafe_left:     direction += right
	if direction != Vector3.ZERO:
		direction = direction.normalized()

	# Air speed
	var speed : float = owner.common_speed_select(direction, is_moving_forward, is_crouching, is_sprinting, was_on_floor)
	owner.apply_horizontal_velocity(direction, speed, was_on_floor)

	# Air gravity
	owner.velocity.y -= owner.settings.gravity * delta

	# Move
	owner.move_and_slide()

	# Landed?
	if owner.is_on_floor():
		owner._grounded_cached = true
		owner.change_state(owner.st_grounded)
	else:
		owner._grounded_cached = false

	owner._handle_animations(is_moving_forward, is_moving_backward, is_crouching, is_sprinting, owner._grounded_cached)
