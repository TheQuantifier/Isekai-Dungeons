extends CanvasLayer
class_name MenusCanvasLayer

signal exit_menu_visibility_changed(visible: bool)

@onready var sun_slider: HSlider = $SunSlider
@onready var view_switch_button: Button = $ViewSwitchButton
@onready var minimap_display: TextureRect = $MiniMapTextureRect
@onready var exit_menu: Control = $ExitMenu

# Compass overlay nodes (children of MiniMapTextureRect)
@onready var minimap_overlay: Control = $MiniMapTextureRect/MinimapOverlay
@onready var compass: TextureRect = $MiniMapTextureRect/MinimapOverlay/Compass

@export_node_path("Node") var game_world_path: NodePath
@onready var game_world: GameWorld = _resolve_game_world()

var sun_rig: SunRig

# Adjust if your compass art points a different default direction (try 90/-90/180)
const COMPASS_ROT_OFFSET_DEG: float = 0.0

func _resolve_game_world() -> GameWorld:
	if String(game_world_path) != "":
		var n := get_node_or_null(game_world_path)
		if n is GameWorld:
			return n
	return get_parent() as GameWorld

func _ready() -> void:
	if game_world == null:
		push_warning("MenusCanvasLayer: Could not resolve GameWorld. Set 'game_world_path' or make it a child of GameWorld.")
		return

	# SunRig
	sun_rig = game_world.get_node_or_null("SunRig") as SunRig
	if sun_rig == null:
		push_warning("MenusCanvasLayer: SunRig not found under GameWorld.")

	# Sun slider (editor wiring for signals)
	sun_slider.min_value = 0.0
	sun_slider.max_value = 180.0
	sun_slider.value = absf(sun_rig.elevation_deg) if sun_rig != null else 45.0

	# View button text
	view_switch_button.focus_mode = Control.FOCUS_NONE
	_update_view_button_text(game_world.is_first_person)

	# Minimap texture + aspect apply (call deferred so layout is final)
	_set_minimap_texture()
	call_deferred("_apply_minimap_shader_aspect")

	# Compass basic setup (no signal connects here; wire in editor)
	_setup_compass()

	# Update compass each frame
	set_process(true)

func _process(_dt: float) -> void:
	_update_compass()

# ---------------- Minimap helpers ----------------

func _set_minimap_texture() -> void:
	if game_world == null or minimap_display == null:
		return
	var tex: Texture2D = game_world.get_minimap_texture()
	if tex != null:
		minimap_display.texture = tex
		minimap_display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_apply_minimap_shader_aspect()
	else:
		call_deferred("_set_minimap_texture")

func _apply_minimap_shader_aspect() -> void:
	if minimap_display == null:
		return
	var mat := minimap_display.material
	if mat is ShaderMaterial:
		var sz: Vector2 = minimap_display.size
		if sz.y > 0.0:
			var aspect: float = max(sz.x, 1.0) / max(sz.y, 1.0)
			(mat as ShaderMaterial).set_shader_parameter("aspect", aspect)

# ---- SIGNAL HANDLER: connect MiniMapTextureRect.resized -> this in the editor
func _on_minimap_resized() -> void:
	_apply_minimap_shader_aspect()

# ---------------- Compass ----------------

func _setup_compass() -> void:
	if minimap_overlay:
		minimap_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if compass:
		compass.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_update_compass_pivot()

# ---- SIGNAL HANDLER: connect Compass.resized -> this in the editor
func _on_compass_resized() -> void:
	_update_compass_pivot()

func _update_compass_pivot() -> void:
	if compass == null:
		return
	# Control pivot in Godot 4:
	compass.pivot_offset = compass.size * 0.5

func _update_compass() -> void:
	if compass == null or game_world == null:
		return

	var heading_deg: float = 0.0

	# Preferred: GameWorld helper if present
	if game_world.has_method("get_player_heading_deg"):
		heading_deg = float(game_world.get_player_heading_deg())
	# Fallback: read player yaw directly
	elif "player" in game_world and is_instance_valid(game_world.player):
		var y_rad: float = game_world.player.global_transform.basis.get_euler().y
		heading_deg = rad_to_deg(y_rad)
	# Last resort: try minimap camera
	elif "minimap_camera" in game_world and is_instance_valid(game_world.minimap_camera):
		var cam_yaw: float = game_world.minimap_camera.global_transform.basis.get_euler().y
		heading_deg = rad_to_deg(cam_yaw)

	# If the map is north-up (−Z at top), rotate the arrow by the player's heading (so it points correctly on a fixed map).
	# If the map rotates with the player (player-up), rotate the arrow opposite so it still points “up.”
	if "minimap_north_up" in game_world and game_world.minimap_north_up:
		compass.rotation_degrees = heading_deg + COMPASS_ROT_OFFSET_DEG
	else:
		compass.rotation_degrees = heading_deg + COMPASS_ROT_OFFSET_DEG

# ---------------- Buttons / Handlers ----------------

func _on_view_switch_button_pressed() -> void:
	if game_world != null:
		game_world.toggle_camera_view()

func _on_camera_view_changed(is_first_person: bool) -> void:
	_update_view_button_text(is_first_person)

func _update_view_button_text(is_first_person: bool) -> void:
	view_switch_button.text = "1st Person" if is_first_person else "3rd Person"

func _on_sun_slider_value_changed(value: float) -> void:
	if sun_rig != null:
		sun_rig.set_ui_elevation_deg(value)
	sun_slider.release_focus()

func _on_exit_button_pressed() -> void:
	toggle_exit_menu()

func toggle_exit_menu() -> void:
	if exit_menu == null:
		return
	exit_menu.visible = not exit_menu.visible  # visibility_changed should be wired in editor if needed

func _on_exit_menu_visibility_changed() -> void:
	exit_menu_visibility_changed.emit(exit_menu.visible)

func _on_inventory_button_pressed() -> void:
	game_manager.go_to(Page.INVENTORY)
