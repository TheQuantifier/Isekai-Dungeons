# res://scenes/game_world/game_world.gd
extends Node3D
class_name GameWorld

signal camera_view_changed(is_first_person: bool)

@onready var player: CharacterBody3D = $Player
@onready var camera_rig: CameraRig = $CameraRig
@onready var sun_rig: SunRig = $SunRig
@onready var env_ctrl: EnvironmentController = $EnvironmentController

@onready var minimap_viewport: SubViewport = $MiniMapViewport
@onready var minimap_camera: Camera3D = $MiniMapViewport/MiniMapCamera

@export var minimap_height: float = 100.0
@export var minimap_size: int = 256
@export var minimap_ortho_size: float = 200.0

var is_first_person := false

# --- Autosave ---
const AUTOSAVE_INTERVAL := 10.0
var _autosave_timer: Timer

# --- NEW: cache last known safe position while we're still in the tree
var _last_player_pos: Vector3 = Vector3.ZERO

func _ready() -> void:
	# Configure sub-systems once (guarded)
	if camera_rig: camera_rig.configure()
	if sun_rig:    sun_rig.configure()
	if env_ctrl:   env_ctrl.configure()

	# Minimap setup (world-owned)
	if minimap_viewport:
		minimap_viewport.size = Vector2i(minimap_size, minimap_size)
		minimap_viewport.disable_3d = false
		minimap_viewport.transparent_bg = true
		minimap_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		minimap_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS

	if minimap_camera:
		minimap_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		minimap_camera.size = minimap_ortho_size
		minimap_camera.current = true  # SubViewport-local

	# Restore player position
	if is_instance_valid(player) and game_manager.current_character and game_manager.current_character.last_position:
		player.global_position = game_manager.current_character.last_position

	# Initialize cached pos if possible
	if is_instance_valid(player) and player.is_inside_tree():
		_last_player_pos = player.global_position

	# Start autosave timer
	_autosave_timer = Timer.new()
	_autosave_timer.wait_time = AUTOSAVE_INTERVAL
	_autosave_timer.one_shot = false
	_autosave_timer.autostart = true
	add_child(_autosave_timer)
	_autosave_timer.timeout.connect(_on_autosave_timeout)

func _process(_dt: float) -> void:
	if not is_instance_valid(player):
		return

	# Keep the cached position fresh while we're in the tree
	if player.is_inside_tree():
		_last_player_pos = player.global_position

	if camera_rig:
		camera_rig.update_follow(player, is_first_person)

	_update_minimap()

func _exit_tree() -> void:
	# Do NOT read player.global_position here (node may be out of the tree).
	# Use the last cached safe value instead.
	game_manager.save_player_position(_last_player_pos)

func _on_autosave_timeout() -> void:
	# Use cached value so autosave is safe even if a scene change is imminent.
	game_manager.save_player_position(_last_player_pos)

# --- Input: keybind (e.g., V mapped to "switch_view") ---
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("switch_view"):
		toggle_camera_view()
		get_viewport().set_input_as_handled()

# --- UI bridge ---
func toggle_camera_view() -> void:
	set_first_person(not is_first_person)

func set_first_person(enable: bool) -> void:
	if is_first_person == enable:
		return
	is_first_person = enable
	emit_signal("camera_view_changed", is_first_person)

func set_sun_elevation_ui(v: float) -> void:
	if sun_rig:
		sun_rig.set_ui_elevation_deg(v)

func get_minimap_texture() -> Texture2D:
	return minimap_viewport.get_texture() if minimap_viewport else null

# --- Internals ---
func _update_minimap() -> void:
	if not (is_instance_valid(player) and minimap_camera):
		return
	var mini_basis := Basis().rotated(Vector3.RIGHT, -PI * 0.5).rotated(Vector3.UP, player.rotation.y + PI)
	minimap_camera.global_transform = Transform3D(
		mini_basis,
		Vector3(_last_player_pos.x, minimap_height, _last_player_pos.z)
	)
