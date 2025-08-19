# res://ui/menus_canvas_layer/menus_canvas_layer.gd
extends CanvasLayer
class_name MenusCanvasLayer

@onready var sun_slider: HSlider = $SunSlider
@onready var view_switch_button: Button = $ViewSwitchButton
@onready var minimap_display: TextureRect = $MiniMapTextureRect
@onready var exit_menu: Control = $ExitMenu   # use Control, not CanvasLayer

var game_world: GameWorld
var sun_rig: SunRig

func _ready() -> void:
	# Resolve GameWorld
	game_world = get_parent() as GameWorld
	if game_world == null:
		push_warning("MenusCanvasLayer: parent is not GameWorld.")
		return

	# Resolve SunRig
	sun_rig = game_world.get_node_or_null("SunRig") as SunRig
	if sun_rig == null:
		push_warning("MenusCanvasLayer: SunRig not found under GameWorld.")

	# Sun slider setup
	sun_slider.min_value = 0.0
	sun_slider.max_value = 180.0
	if sun_rig != null:
		sun_slider.value = absf(sun_rig.elevation_deg)
	else:
		sun_slider.value = 45.0
	if not sun_slider.value_changed.is_connected(_on_sun_slider_value_changed):
		sun_slider.value_changed.connect(_on_sun_slider_value_changed)

	# View button
	view_switch_button.focus_mode = Control.FOCUS_NONE
	_update_view_button_text(game_world.is_first_person)
	if game_world.has_signal("camera_view_changed"):
		if not game_world.camera_view_changed.is_connected(_on_camera_view_changed):
			game_world.camera_view_changed.connect(_on_camera_view_changed)

	# Minimap texture via world API
	if game_world.has_method("get_minimap_texture"):
		var tex := game_world.get_minimap_texture()
		if tex != null:
			minimap_display.texture = tex
			minimap_display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

func _center_control_to_viewport(c: Control) -> void:
	if not is_instance_valid(c):
		return
	var vr := get_viewport().get_visible_rect().size
	if c.size == Vector2.ZERO:
		call_deferred("_center_control_to_viewport", c)
		return
	c.position = vr * 0.5 - c.size * 0.5

# --- Buttons / Handlers ---
func _on_view_switch_button_pressed() -> void:
	if game_world != null:
		game_world.toggle_camera_view()  # GameWorld will emit camera_view_changed

func _on_camera_view_changed(is_first_person: bool) -> void:
	_update_view_button_text(is_first_person)

func _update_view_button_text(is_first_person: bool) -> void:
	if is_first_person:
		view_switch_button.text = "1st Person"
	else:
		view_switch_button.text = "3rd Person"

func _on_sun_slider_value_changed(value: float) -> void:
	if sun_rig != null:
		sun_rig.set_ui_elevation_deg(value)
	sun_slider.release_focus()

func _on_exit_button_pressed() -> void:
	if exit_menu != null:
		exit_menu.visible = true

func _on_inventory_button_pressed() -> void:
	game_manager.go_to("stats")
