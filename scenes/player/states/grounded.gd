extends PlayerState

func enter(_prev):
	# optional: snap animation on enter
	pass

func physics_update(delta: float) -> void:
	if owner.in_water:
		owner.change_state(owner.st_swimming)
		return

	var was_on_floor := owner.is_on_floor()
	if not was_on_floor:
		owner.change_state(owner.st_airborne)
		return

	# Input
	var is_moving_forward := Input.is_action_pressed("move_forward")
	var is_moving_backward := Input.is_action_pressed("move_back")
	var is_turning_left := Input.is_action_pressed("move_left")
	var is_turning_right := Input.is_action_pressed("move_right")
	var is_strafe_left := Input.is_action_pressed("strafe_left")
	var is_strafe_right := Input.is_action_pressed("strafe_right")
	var is_crouching := Input.is_action_pressed("crouch")
	var is_sprinting := Input.is_action_pressed("sprint")
	var jump_pressed := Input.is_action_just_pressed("jump")

	# Turn character
	var turn_rate : float = (owner.settings.water_turn_speed if owner.in_water else owner.settings.turn_speed)
	if is_turning_left:
		owner.rotate_y(turn_rate * delta)
	if is_turning_right:
		owner.rotate_y(-turn_rate * delta)

	# Movement vectors
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

	# Speed + horizontal velocity
	var speed : float = owner.common_speed_select(direction, is_moving_forward, is_crouching, is_sprinting, was_on_floor)
	owner.apply_horizontal_velocity(direction, speed, was_on_floor)

	# Vertical (ground stick)
	owner.land_gravity_and_stick(delta, was_on_floor)

	# Jump
	if jump_pressed and was_on_floor:
		owner.velocity.y = owner.settings.jump_velocity
		owner.is_jumping = true
		var planar_speed := Vector2(owner.velocity.x, owner.velocity.z).length()
		if planar_speed <= owner.LAND_STILL_EPS:
			owner._play("jump_stat", owner.settings.anim_jump_stat)
		else:
			owner._play("jump", owner.settings.anim_jump)
		owner.change_state(owner.st_airborne)

	# Move/apply + snap
	owner.move_and_slide()
	if owner.velocity.y <= 0.0 and not owner.in_water:
		owner.apply_floor_snap()

	# Cache grounded AFTER move
	owner._grounded_cached = owner.is_on_floor()

	# Animations
	owner._handle_animations(is_moving_forward, is_moving_backward, is_crouching, is_sprinting, owner._grounded_cached)
