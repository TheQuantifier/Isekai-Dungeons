# res://scenes/game_world/GameWorld.gd
extends Node3D

@onready var player: CharacterBody3D = $Player
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D

@onready var sun_pivot: Node3D = $SunPivot
@onready var visible_sun: MeshInstance3D = $SunPivot/VisibleSun
@onready var sun_light: DirectionalLight3D = $SunPivot/DirectionalLight3D
@onready var world_env: WorldEnvironment = $WorldEnvironment

const SUN_DISTANCE: float = 1000.0
const SUN_ELEVATION_DEGREES: float = -90.0
const SUN_AZIMUTH_DEGREES: float = -45.0

func _ready() -> void:
	# ☀️ Make the sun visible and properly directional
	sun_light.light_energy = 1.0  # ← your requested value
	sun_light.light_color = Color(1.0, 0.95, 0.85)
	sun_light.shadow_enabled = true
	sun_light.shadow_bias = 0.05
	sun_light.shadow_normal_bias = 0.5

	# 🌎 Adjust environment exposure to help sunlight show better
	var env = world_env.environment
	env.adjustment_enabled = true
	env.set("adjustment/exposure", 1.5)
	
	# 🌤️ Optional: reduce ambient light if it overpowers the sun
	env.ambient_light_energy = 0.5
	env.ambient_light_sky_contribution = 0.5

	# ✨ Add glow to the visible sun (mesh)
	var mat := StandardMaterial3D.new()
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.85, 0.5)
	mat.emission_energy = 10.0
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	visible_sun.set_surface_override_material(0, mat)

func _process(_delta: float) -> void:
	# Update camera position
	var player_transform = player.global_transform
	var back_offset = -player_transform.basis.z.normalized() * 3.5
	var up_offset = Vector3.UP * 2.0
	var camera_position = player_transform.origin + back_offset + up_offset
	camera_pivot.global_position = camera_position
	camera.look_at(player_transform.origin, Vector3.UP)
	
	# Update sun direction and position
	var elevation_rad = deg_to_rad(SUN_ELEVATION_DEGREES)
	var azimuth_rad = deg_to_rad(SUN_AZIMUTH_DEGREES)
	
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
