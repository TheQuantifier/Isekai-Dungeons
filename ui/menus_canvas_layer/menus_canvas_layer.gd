extends CanvasLayer
class_name MenusCanvasLayer

signal exit_menu_visibility_changed(visible: bool)  # NEW

@onready var sun_slider: HSlider = $SunSlider
@onready var view_switch_button: Button = $ViewSwitchButton
@onready var minimap_display: TextureRect = $MiniMapTextureRect
@onready var exit_menu: Control = $ExitMenu

@export_node_path("Node") var game_world_path: NodePath
@onready var game_world: GameWorld = _resolve_game_world()

var sun_rig: SunRig

func _resolve_game_world() -> GameWorld:
	if String(game_world_path) != "":
		var n := get_node_or_null(game_world_path)
		if n is GameWorld:
			return n
	var p := get_parent()
	return p as GameWorld

func _ready() -> void:
	if game_world == null:
		push_warning("MenusCanvasLayer: Could not resolve GameWorld. Set 'game_world_path' or make it a child of GameWorld.")
		return

	# SunRig
	sun_rig = game_world.get_node_or_null("SunRig") as SunRig
	if sun_rig == null:
		push_warning("MenusCanvasLayer: SunRig not found under GameWorld.")

	# Sun slider
	sun_slider.min_value = 0.0
	sun_slider.max_value = 180.0
	sun_slider.value = absf(sun_rig.elevation_deg) if sun_rig != null else 45.0
	if not sun_slider.value_changed.is_connected(_on_sun_slider_value_changed):
		sun_slider.value_changed.connect(_on_sun_slider_value_changed)

	# View button
	view_switch_button.focus_mode = Control.FOCUS_NONE
	_update_view_button_text(game_world.is_first_person)
	if game_world.has_signal("camera_view_changed") and not game_world.camera_view_changed.is_connected(_on_camera_view_changed):
		game_world.camera_view_changed.connect(_on_camera_view_changed)

	# Minimap texture
	_set_minimap_texture()

	# NEW: watch Exit Menu visibility changes
	if exit_menu and not exit_menu.visibility_changed.is_connected(_on_exit_menu_visibility_changed):
		exit_menu.visibility_changed.connect(_on_exit_menu_visibility_changed)

func _set_minimap_texture() -> void:
	if game_world == null or minimap_display == null:
		return
	var tex := game_world.get_minimap_texture()
	if tex != null:
		minimap_display.texture = tex
		minimap_display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	else:
		call_deferred("_set_minimap_texture")

# --- Buttons / Handlers ---
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

# CHANGED: just toggle; do NOT save here
func _on_exit_button_pressed() -> void:
	toggle_exit_menu()

# NEW: single source of truth for opening/closing
func toggle_exit_menu() -> void:
	if exit_menu == null:
		return
	exit_menu.visible = not exit_menu.visible  # triggers visibility_changed signal

# NEW: emit signal upward with current visibility
func _on_exit_menu_visibility_changed() -> void:
	exit_menu_visibility_changed.emit(exit_menu.visible)


func _on_inventory_button_pressed() -> void:
	game_manager.go_to(Page.INVENTORY)
