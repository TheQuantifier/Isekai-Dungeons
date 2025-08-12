extends Node3D
class_name GameWorld

@onready var player: CharacterBody3D = $Player
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera_third: Camera3D = $CameraPivot/Camera3D
@onready var camera_first: Camera3D = $CameraPivot/Camera3D_FirstPerson

@onready var sun_pivot: Node3D = $SunPivot
@onready var visible_sun: MeshInstance3D = $SunPivot/VisibleSun
@onready var sun_light: DirectionalLight3D = $SunPivot/DirectionalLight3D
@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var sun_slider: HSlider = $MenusCanvasLayer/SunSlider
@onready var stats_button: Button = $MenusCanvasLayer/VBoxContainer/StatsButton
@onready var view_switch_button: Button = $MenusCanvasLayer/VBoxContainer/ViewSwitchButton
@onready var menus_canvas: CanvasLayer = $MenusCanvasLayer

@onready var minimap_viewport: SubViewport = $MiniMapViewport
@onready var minimap_camera: Camera3D = $MiniMapViewport/MiniMapCamera
@onready var minimap_display: TextureRect = $MenusCanvasLayer/MiniMapTextureRect

const SUN_DISTANCE: float = 1000.0
const MINIMAP_HEIGHT: float = 100.0

var sun_elevation_degrees: float = -25.0
var sun_azimuth_degrees: float = -30.0

var is_first_person := false
var stats_panel: Control = null

func _ready() -> void:
	# ☀️ Light setup
	sun_light.light_energy = 1.0
	sun_light.light_color = Color(1.0, 0.95, 0.85)
	sun_light.shadow_enabled = true
	sun_light.shadow_bias = 0.05
	sun_light.shadow_normal_bias = 0.5

	# 🌎 Environment
	var env = world_env.environment
	env.adjustment_enabled = true
	env.set("adjustment/exposure", 1.5)
	env.ambient_light_energy = 0.5
	env.ambient_light_sky_contribution = 0.5

	# ✨ Sun glow material
	var mat := StandardMaterial3D.new()
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.85, 0.5)
	mat.emission_energy = 10.0
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	visible_sun.set_surface_override_material(0, mat)

	# 🎚️ Sun slider
	sun_slider.min_value = 0.0
	sun_slider.max_value = 180.0
	sun_slider.value = abs(sun_elevation_degrees)

	# 🖱️ UI focus
	stats_button.focus_mode = Control.FOCUS_NONE
	view_switch_button.focus_mode = Control.FOCUS_NONE

	# 🔘 Initial camera view
	view_switch_button.text = "3rd Person"

	# 🧭 Minimap setup
	minimap_viewport.size = Vector2i(256, 256)
	minimap_viewport.disable_3d = false
	minimap_viewport.transparent_bg = true
	minimap_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	minimap_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS

	minimap_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	minimap_camera.size = 200.0  # Adjust for zoom
	minimap_camera.current = true

	minimap_display.texture = minimap_viewport.get_texture()
	minimap_display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# Position Character at saved location:
	if game_manager.current_character and game_manager.current_character.last_position:
		player.global_position = game_manager.current_character.last_position
		
func _process(_delta: float) -> void:
	var player_transform = player.global_transform

	if is_first_person:
		# 👁️ 1st person: eye-level, parallel to horizon
		var head_offset = Vector3.UP * 1.6
		var forward_offset = player_transform.basis.z.normalized() * 0.2
		camera_pivot.global_position = player_transform.origin + head_offset + forward_offset
		camera_first.global_rotation = Vector3(0, player_transform.basis.get_euler().y + PI, 0)
	else:
		# 🎥 3rd person: over-the-shoulder
		var back_offset = -player_transform.basis.z.normalized() * 3.5
		var up_offset = Vector3.UP * 2.0
		camera_pivot.global_position = player_transform.origin + back_offset + up_offset
		camera_third.look_at(player_transform.origin + Vector3.UP * 1.5, Vector3.UP)

	# ✅ Keep view switch button visible
	view_switch_button.visible = true

	# ☀️ Sun positioning
	var elevation_rad = deg_to_rad(sun_elevation_degrees)
	var azimuth_rad = deg_to_rad(sun_azimuth_degrees)

	var sun_direction = Vector3(
		cos(elevation_rad) * cos(azimuth_rad),
		sin(elevation_rad),
		cos(elevation_rad) * sin(azimuth_rad)
	).normalized()

	var fallback_up = Vector3(0, 0, 1)
	var up_vector = Vector3.UP
	if abs(sun_direction.dot(Vector3.UP)) > 0.99:
		up_vector = fallback_up

	sun_pivot.look_at(sun_pivot.global_transform.origin + sun_direction, up_vector)
	visible_sun.global_position = sun_direction * SUN_DISTANCE

	# 🧭 Update minimap camera position and rotation
	var minimap_basis := Basis()
	minimap_basis = minimap_basis.rotated(Vector3.RIGHT, -PI / 2)  # Look down
	minimap_basis = minimap_basis.rotated(Vector3.UP, player.global_rotation.y + PI)  # Match player heading

	minimap_camera.global_transform = Transform3D(
		minimap_basis,
		Vector3(player.global_position.x, MINIMAP_HEIGHT, player.global_position.z)
	)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("switch_view"):
		_toggle_camera_view()

func _on_view_switch_button_pressed() -> void:
	_toggle_camera_view()

func _toggle_camera_view() -> void:
	is_first_person = !is_first_person
	camera_first.current = is_first_person
	camera_third.current = not is_first_person

	if is_first_person:
		view_switch_button.text = "1st Person"
	else:
		view_switch_button.text = "3rd Person"

func _on_main_menu_pressed() -> void:
	game_manager.save_player_position(player.global_position)
	game_manager.go_to("main_menu")

func _on_sun_slider_changed(value: float) -> void:
	sun_elevation_degrees = -clamp(value, 0.0, 180.0)
	sun_slider.release_focus()

func _on_stats_button_pressed() -> void:
	if stats_panel == null:
		stats_panel = load("res://ui/stats_view/stats_view.tscn").instantiate()
		menus_canvas.add_child(stats_panel)
		stats_panel.position = get_viewport().get_visible_rect().size / 2 - stats_panel.size / 2
	else:
		stats_panel.visible = not stats_panel.visible


func _on_exit_button_pressed() -> void:
	$MenusCanvasLayer/ExitMenu.visible = true
	
