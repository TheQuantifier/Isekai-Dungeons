# res://ai/AIBox.gd
extends CharacterBody3D

@onready var agent: NavigationAgent3D = $Agent

@export var move_speed: float = 3.0
@export var turn_speed: float = 6.0
@export var wander_radius: float = 20.0
@export var idle_time_range: Vector2 = Vector2(0.3, 1.2) # seconds
@export var repick_if_no_path: bool = true

var _idle_timer: float = 0.0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	_pick_new_target_or_wait()

func _physics_process(delta: float) -> void:
	# Idle countdown
	if _idle_timer > 0.0:
		_idle_timer -= delta
		return

	# If path finished, pick another target and idle briefly
	if agent.is_navigation_finished():
		_pick_new_target_or_wait()
		return

	# Move toward next path point
	var next_pos: Vector3 = agent.get_next_path_position()

	var to_target: Vector3 = next_pos - global_position
	to_target.y = 0.0
	var dir: Vector3 = to_target.normalized()

	# Turn toward movement direction
	if dir.length() > 0.001:
		var desired_yaw: float = atan2(-dir.x, -dir.z) # Godot forward is -Z
		var current_yaw: float = rotation.y
		var delta_yaw: float = wrapf(desired_yaw - current_yaw, -PI, PI)
		rotation.y += clamp(delta_yaw, -turn_speed * delta, turn_speed * delta)

	# Step forward along our local forward
	var planar: Vector3 = -transform.basis.z * move_speed
	velocity.x = planar.x
	velocity.z = planar.z
	velocity.y = 0.0 # float; add gravity here if you want

	move_and_slide()

	# Feed velocity to agent for avoidance
	agent.set_velocity(velocity)
	agent.set_target_desired_distance(0.25)

func _pick_new_target_or_wait() -> void:
	# Idle briefly between targets for a more organic feel
	_idle_timer = _rng.randf_range(idle_time_range.x, idle_time_range.y)

	var map_rid: RID = get_world_3d().navigation_map
	if not map_rid.is_valid():
		return

	# Pick random point in a disc, then project it onto the navmesh
	var local := _random_point_in_disc(wander_radius)
	var raw_target := global_position + Vector3(local.x, 0.0, local.y)
	var nav_target: Vector3 = NavigationServer3D.map_get_closest_point(map_rid, raw_target)

	agent.set_target_position(nav_target)

	if repick_if_no_path:
		# Wait a frame so the path can compute (signal, not a function)
		await get_tree().process_frame
		var path: PackedVector3Array = agent.get_current_navigation_path()
		if path.size() <= 1:
			# Try again immediately (cancel idle wait)
			_idle_timer = 0.0

func _random_point_in_disc(radius: float) -> Vector2:
	var ang := _rng.randf_range(0.0, TAU)
	var r := radius * sqrt(_rng.randf()) # uniform over disc
	return Vector2(cos(ang), sin(ang)) * r
