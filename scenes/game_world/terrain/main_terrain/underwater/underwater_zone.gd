# res://scenes/game_world/terrain/main_terrain/underwater/underwater_zone_castle.gd
extends Area3D

const UNDERWATER_ENV_PATH := "res://scenes/game_world/terrain/main_terrain/underwater/underwater_environment.tres"

@export var water_level: float = -5.0          # Manual Y height of water surface
@export var surface_clear_margin: float = 1.0  # must be this far below surface to apply underwater env

var underwater_env: Environment
var _prev_env: Environment = null
var _using_underwater: bool = false
var _player: Node3D = null
var _inside_area: bool = false

func _ready() -> void:
	monitoring = true
	monitorable = true

	underwater_env = load(UNDERWATER_ENV_PATH)
	if underwater_env == null:
		push_warning("UnderwaterZone: failed to load environment at %s" % UNDERWATER_ENV_PATH)

	# connect once (ignore if already wired in editor)
	var cb_enter := Callable(self, "_on_body_entered")
	if not body_entered.is_connected(cb_enter):
		body_entered.connect(cb_enter)
	var cb_exit := Callable(self, "_on_body_exited")
	if not body_exited.is_connected(cb_exit):
		body_exited.connect(cb_exit)

func _process(_dt: float) -> void:
	if _player == null:
		return

	# Visuals: only show underwater env when truly submerged
	var submerged := _is_submerged(_player)
	if submerged and not _using_underwater:
		_apply_underwater_environment()
	elif (not submerged) and _using_underwater:
		_restore_environment()

	# Physics: keep in_water true while inside the area (regardless of submerged)
	if _player.has_method("set_in_water"):
		_player.set_in_water(_inside_area)

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	_player = body
	_inside_area = true

func _on_body_exited(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	_inside_area = false

	# Leaving the zone: restore clear environment and clear water flag
	if _using_underwater:
		_restore_environment()
	if body.has_method("set_in_water"):
		body.set_in_water(false)
	_player = null

# --- Helpers ---

func _apply_underwater_environment() -> void:
	var vp := get_viewport()
	if vp and vp.world_3d:
		if _prev_env == null:
			_prev_env = vp.world_3d.environment
		if underwater_env:
			vp.world_3d.environment = underwater_env
			_using_underwater = true

func _restore_environment() -> void:
	var vp := get_viewport()
	if vp and vp.world_3d and _prev_env:
		vp.world_3d.environment = _prev_env
	_using_underwater = false
	_prev_env = null

func _is_submerged(body: Node3D) -> bool:
	# Underwater only if player is clearly below the fixed water surface
	return body.global_position.y < (water_level - surface_clear_margin)
