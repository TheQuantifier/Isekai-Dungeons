extends Node3D
class_name GameWorld

# -------------------------------------------------------------------
# Signals
# -------------------------------------------------------------------
signal camera_view_changed(is_first_person: bool)

# -------------------------------------------------------------------
# Node references (assigned in scene tree)
# -------------------------------------------------------------------
@onready var player: CharacterBody3D = $Player
@onready var sun_rig: SunRig = $SunRig
@onready var env_ctrl: EnvironmentController = $EnvironmentController
@onready var menus: MenusCanvasLayer = $MenusCanvasLayer

@onready var minimap_viewport: SubViewport = $MiniMapViewport
@onready var minimap_camera: Camera3D = $MiniMapViewport/MiniMapCamera

# -------------------------------------------------------------------
# Minimap configuration
# -------------------------------------------------------------------
@export var minimap_height: float = 100.0         # Height above player
@export var minimap_size: int = 256               # Render texture size
@export var minimap_ortho_size: float = 200.0     # Zoom level (orthographic size)

# -------------------------------------------------------------------
# State
# -------------------------------------------------------------------
var is_first_person := false
const AUTOSAVE_INTERVAL := 10.0
var _autosave_timer: Timer
var _last_player_pos: Vector3 = Vector3.ZERO

# -------------------------------------------------------------------
# Lifecycle
# -------------------------------------------------------------------
func _ready() -> void:
	# Configure subsystems
	if sun_rig:    sun_rig.configure()
	if env_ctrl:   env_ctrl.configure()

	# --- Minimap setup ---
	if minimap_viewport:
		minimap_viewport.size = Vector2i(minimap_size, minimap_size)
		minimap_viewport.disable_3d = false
		minimap_viewport.transparent_bg = true
		minimap_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		minimap_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS

	if minimap_camera:
		minimap_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		minimap_camera.size = minimap_ortho_size
		minimap_camera.current = true

	# --- Restore player position from save ---
	if is_instance_valid(player) \
	and game_manager.current_character \
	and game_manager.current_character.last_position:
		player.global_position = game_manager.current_character.last_position + Vector3.UP

	# --- Initialize position cache ---
	if is_instance_valid(player) and player.is_inside_tree():
		_last_player_pos = player.global_position

	# --- Start autosave timer ---
	_autosave_timer = Timer.new()
	_autosave_timer.wait_time = AUTOSAVE_INTERVAL
	_autosave_timer.one_shot = false
	_autosave_timer.autostart = true
	add_child(_autosave_timer)
	_autosave_timer.timeout.connect(_on_autosave_timeout)

	# --- Listen for Exit Menu visibility (autosave trigger) ---
	if is_instance_valid(menus) \
	and not menus.exit_menu_visibility_changed.is_connected(_on_exit_menu_visibility_changed):
		menus.exit_menu_visibility_changed.connect(_on_exit_menu_visibility_changed)

func _process(_dt: float) -> void:
	# Update cached player position (used for minimap and fallbacks)
	if is_instance_valid(player) and player.is_inside_tree():
		_last_player_pos = player.global_position

	# Minimap follow
	_update_minimap()

func _exit_tree() -> void:
	# Route saves through GameManager's safety-checked path
	if is_instance_valid(player):
		game_manager.save_position_from(player)

# -------------------------------------------------------------------
# Autosave
# -------------------------------------------------------------------
func _on_autosave_timeout() -> void:
	# Safety-checked save (won't overwrite while swimming or mid-air)
	if is_instance_valid(player):
		game_manager.save_position_from(player)

func _on_exit_menu_visibility_changed(menu_visible: bool) -> void:
	# Safety-checked save when exit menu opens
	if menu_visible and is_instance_valid(player):
		game_manager.save_position_from(player)

# -------------------------------------------------------------------
# Input handling
# -------------------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("switch_view"):
		toggle_camera_view()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inventory"):
		game_manager.go_to(Page.INVENTORY)

# -------------------------------------------------------------------
# Camera view management (delegates to Player)
# -------------------------------------------------------------------
func toggle_camera_view() -> void:
	set_first_person(not is_first_person)

func set_first_person(enable: bool) -> void:
	if is_first_person == enable:
		return
	is_first_person = enable
	# Forward to Player's camera rig
	if is_instance_valid(player) and player.has_method("set_first_person"):
		player.set_first_person(is_first_person)
	emit_signal("camera_view_changed", is_first_person)

# -------------------------------------------------------------------
# Environment controls
# -------------------------------------------------------------------
func set_sun_elevation_ui(v: float) -> void:
	if sun_rig:
		sun_rig.set_ui_elevation_deg(v)

# -------------------------------------------------------------------
# Minimap helpers
# -------------------------------------------------------------------
func get_minimap_texture() -> Texture2D:
	return minimap_viewport.get_texture() if minimap_viewport else null

func get_player_heading_deg() -> float:
	# Useful for compass overlays
	if not is_instance_valid(player):
		return 0.0
	var y_rad: float = player.global_transform.basis.get_euler().y
	return rad_to_deg(y_rad)

func _update_minimap() -> void:
	# Update minimap camera to follow player top-down
	if not (is_instance_valid(player) and minimap_camera):
		return
	var mini_basis := Basis() \
		.rotated(Vector3.RIGHT, -PI * 0.5) \
		.rotated(Vector3.UP, player.rotation.y + PI)

	minimap_camera.global_transform = Transform3D(
		mini_basis,
		Vector3(
			_last_player_pos.x,
			_last_player_pos.y + minimap_height,
			_last_player_pos.z
		)
	)

# -------------------------------------------------------------------
# Utility
# -------------------------------------------------------------------
func get_player_position() -> Vector3:
	return player.global_position if is_instance_valid(player) else Vector3.ZERO
