# res://scenes/game_world/game_world.gd
extends Node3D
class_name GameWorld

# --- Scene refs ---
@onready var player: CharacterBody3D = $Player
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera_third: Camera3D = $CameraPivot/Camera3D
@onready var camera_first: Camera3D = $CameraPivot/Camera3D_FirstPerson

@onready var sun_pivot: Node3D = $SunPivot
@onready var visible_sun: MeshInstance3D = $SunPivot/VisibleSun
@onready var sun_light: DirectionalLight3D = $SunPivot/DirectionalLight3D
@onready var world_env: WorldEnvironment = $WorldEnvironment

@onready var sun_slider: HSlider = $MenusCanvasLayer/SunSlider
@onready var view_switch_button: Button = $MenusCanvasLayer/ViewSwitchButton
@onready var menus_canvas: CanvasLayer = $MenusCanvasLayer

@onready var minimap_viewport: SubViewport = $MiniMapViewport
@onready var minimap_camera: Camera3D = $MiniMapViewport/MiniMapCamera
@onready var minimap_display: TextureRect = $MenusCanvasLayer/MiniMapTextureRect

# --- Tunables ---
@export var sun_distance: float = 1000.0
@export var minimap_height: float = 100.0
@export_range(-90.0, 90.0, 0.1) var sun_elevation_degrees: float = -25.0
@export_range(-180.0, 180.0, 0.1) var sun_azimuth_degrees: float = -30.0
@export var third_person_back: float = 3.5
@export var third_person_up: float = 2.0
@export var first_person_head_height: float = 1.6
@export var first_person_forward_offset: float = 0.2
@export var minimap_size: int = 256
@export var minimap_ortho_size: float = 200.0

# --- State ---
var is_first_person: bool = false
var stats_panel: Control = null

func _ready() -> void:
	# ☀️ Light setup
	sun_light.light_energy = 1.0
	sun_light.light_color = Color(1.0, 0.95, 0.85)
	sun_light.shadow_enabled = true
	sun_light.shadow_bias = 0.05
	sun_light.shadow_normal_bias = 0.5

	# 🌎 Environment
	var env := world_env.environment
	if env:
		env.adjustment_enabled = true
		env.tonemap_exposure = 1.5  # Godot 4.x exposure property
		env.ambient_light_energy = 0.5
		env.ambient_light_sky_contribution = 0.5

	# ✨ Sun glow material
	var mat := StandardMaterial3D.new()
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.85, 0.5)
	mat.emission_energy = 10.0
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	visible_sun.set_surface_override_material(0, mat)

	# 🎚️ Sun slider (UI shows absolute, engine keeps negative to point down)
	sun_slider.min_value = 0.0
	sun_slider.max_value = 180.0
	sun_slider.value = absf(sun_elevation_degrees)

	# 🖱️ UI focus
	view_switch_button.focus_mode = Control.FOCUS_NONE
	view_switch_button.text = "3rd Person"

	# 🧭 Minimap setup
	minimap_viewport.size = Vector2i(minimap_size, minimap_size)
	minimap_viewport.disable_3d = false
	minimap_viewport.transparent_bg = true
	minimap_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	minimap_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS

	minimap_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	minimap_camera.size = minimap_ortho_size
	minimap_camera.current = true

	minimap_display.texture = minimap_viewport.get_texture()
	minimap_display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	# ▶️ Restore player position if present
	if game_manager.current_character and game_manager.current_character.last_position:
		player.global_position = game_manager.current_character.last_position

	# Make cameras deterministic: pivot rotates, cameras stay local-zero
	camera_first.rotation = Vector3.ZERO
	camera_third.rotation = Vector3.ZERO

func _process(_delta: float) -> void:
	update_camera()
	update_sun()
	update_minimap()

func update_camera() -> void:
	var t := player.global_transform
	var forward := t.basis.z.normalized()
	var head := Vector3.UP * first_person_head_height

	if is_first_person:
		# Eye‑level, slightly in front so we never see the face
		camera_pivot.global_position = t.origin + head + Vector3(0, 0.75, 0) + forward * first_person_forward_offset
		# Yaw only; pitch is typically handled by input elsewhere if desired
		camera_pivot.rotation.y = player.rotation.y + PI
		camera_first.current = true
		camera_third.current = false
	else:
		# Over‑the‑shoulder third‑person
		camera_pivot.global_position = t.origin - forward * third_person_back + Vector3.UP * third_person_up
		camera_third.look_at(t.origin + Vector3.UP * 1.5, Vector3.UP)
		camera_first.current = false
		camera_third.current = true

	# Keep the toggle visible (in case other code hides it)
	view_switch_button.visible = true

func update_sun() -> void:
	var elev := deg_to_rad(sun_elevation_degrees)
	var azim := deg_to_rad(sun_azimuth_degrees)

	var dir := Vector3(
		cos(elev) * cos(azim),
		sin(elev),
		cos(elev) * sin(azim)
	).normalized()

	# Avoid gimbal when nearly vertical
	var up := Vector3.UP
	if absf(dir.dot(Vector3.UP)) > 0.99:
		up = Vector3(0, 0, 1)

	sun_pivot.look_at(sun_pivot.global_transform.origin + dir, up)
	visible_sun.global_position = dir * sun_distance

func update_minimap() -> void:
	var cam_basis := Basis()
	cam_basis = cam_basis.rotated(Vector3.RIGHT, -PI * 0.5)
	cam_basis = cam_basis.rotated(Vector3.UP, player.rotation.y + PI)

	minimap_camera.global_transform = Transform3D(
		cam_basis,
		Vector3(player.global_position.x, minimap_height, player.global_position.z)
	)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("switch_view"):
		_toggle_camera_view()
		get_viewport().set_input_as_handled()
	
	elif event.is_action_pressed("inventory"):
		game_manager.go_to("stats")

func _on_view_switch_button_pressed() -> void:
	_toggle_camera_view()

func _toggle_camera_view() -> void:
	is_first_person = !is_first_person
	if is_first_person:
		view_switch_button.text = "1st Person"
	else:
		view_switch_button.text = "3rd Person"

func _on_main_menu_pressed() -> void:
	game_manager.save_player_position(player.global_position)
	game_manager.go_to("main_menu")

func _on_sun_slider_changed(value: float) -> void:
	# Keep negative elevation to point the light toward the ground (your preference)
	sun_elevation_degrees = -clampf(value, 0.0, 180.0)
	sun_slider.release_focus()

func _on_stats_button_pressed() -> void:
	if stats_panel == null:
		var stats_scene := preload("res://ui/stats_view/stats_view.tscn") as PackedScene
		var p: Control = stats_scene.instantiate()
		stats_panel = p
		menus_canvas.add_child(p)
		# Center after it's been laid out
		call_deferred("_center_control_to_viewport", p)
	else:
		stats_panel.visible = not stats_panel.visible

# --- Helpers ---
func _center_control_to_viewport(c: Control) -> void:
	if not is_instance_valid(c):
		return
	var vr := get_viewport().get_visible_rect().size
	# If size is not ready yet, try again on next idle frame
	if c.size == Vector2.ZERO:
		call_deferred("_center_control_to_viewport", c)
		return
	c.position = vr * 0.5 - c.size * 0.5

func _on_exit_button_pressed() -> void:
	$MenusCanvasLayer/ExitMenu.visible = true


func _on_inventory_button_pressed() -> void:
	game_manager.go_to("stats")
