# res://scenes/game_world/GameWorld.gd
extends Node3D

@onready var player: CharacterBody3D = $Player
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D

@onready var sun_pivot: Node3D = $SunPivot
@onready var visible_sun: MeshInstance3D = $SunPivot/VisibleSun
@onready var sun_light: DirectionalLight3D = $SunPivot/DirectionalLight3D
@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var sun_slider: HSlider = $MenusCanvasLayer/SunSlider
@onready var stats_button: Button = $MenusCanvasLayer/VBoxContainer/StatsButton
@onready var menus_canvas: CanvasLayer = $MenusCanvasLayer

const SUN_DISTANCE: float = 1000.0
var sun_elevation_degrees: float = -25.0  # Negative to point downward
var sun_azimuth_degrees: float = -30.0    # Fixed azimuth for now

var stats_panel: Control = null

func _ready() -> void:
	# ☀️ Setup directional light
	sun_light.light_energy = 1.0
	sun_light.light_color = Color(1.0, 0.95, 0.85)
	sun_light.shadow_enabled = true
	sun_light.shadow_bias = 0.05
	sun_light.shadow_normal_bias = 0.5

	# 🌎 Environment settings
	var env = world_env.environment
	env.adjustment_enabled = true
	env.set("adjustment/exposure", 1.5)
	env.ambient_light_energy = 0.5
	env.ambient_light_sky_contribution = 0.5

	# ✨ Glow for sun mesh
	var mat := StandardMaterial3D.new()
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.85, 0.5)
	mat.emission_energy = 10.0
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	visible_sun.set_surface_override_material(0, mat)

	# 🎛️ Hook up sun slider (0 to 180 gets mapped to 0 to -180)
	sun_slider.min_value = 0.0
	sun_slider.max_value = 180.0
	sun_slider.value = abs(sun_elevation_degrees)

	# 🎮 Connect stats button
	stats_button.focus_mode = Control.FOCUS_NONE

func _process(_delta: float) -> void:
	# 🎥 Update camera position
	var player_transform = player.global_transform
	var back_offset = -player_transform.basis.z.normalized() * 3.5
	var up_offset = Vector3.UP * 2.0
	var camera_position = player_transform.origin + back_offset + up_offset
	camera_pivot.global_position = camera_position
	var look_target = player_transform.origin + Vector3.UP * 1.5
	camera.look_at(look_target, Vector3.UP)

	# ☀️ Update sun direction and position
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

func _on_main_menu_pressed() -> void:
	game_manager.go_to_main_menu()

func _on_sun_slider_changed(value: float) -> void:
	# Convert slider value (0 to 180) to elevation angle (0 to -180)
	sun_elevation_degrees = -clamp(value, 0.0, 180.0)
	sun_slider.release_focus()

func _on_stats_button_pressed() -> void:
	if stats_panel == null:
		stats_panel = load("res://ui/stats_view/stats_view.tscn").instantiate()
		menus_canvas.add_child(stats_panel)
		stats_panel.position = get_viewport().get_visible_rect().size / 2 - stats_panel.size / 2
	else:
		stats_panel.visible = not stats_panel.visible
