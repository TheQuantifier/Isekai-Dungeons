# res://scenes/rigs/sun_rig/sun_rig.gd
extends Node3D
class_name SunRig

@onready var visible_sun: MeshInstance3D = $VisibleSun
@onready var sun_light: DirectionalLight3D = $DirectionalLight3D

# --- Tunables ---
@export var sun_distance: float = 1000.0
@export_range(-90, 90, 0.1) var elevation_deg: float = -25.0   # negative = pointing down (your convention)
@export_range(-180, 180, 0.1) var azimuth_deg: float = -30.0

@export var sun_energy: float = 0.5
@export var sun_color: Color = Color(1.0, 0.95, 0.85)
@export var shadow_bias: float = 0.05
@export var shadow_normal_bias: float = 0.5

@export var glow_color: Color = Color(1.0, 0.85, 0.5)
@export var glow_energy: float = 10.0
@export var auto_configure_on_ready: bool = true

var _glow_mat: StandardMaterial3D = null

func _ready() -> void:
	if auto_configure_on_ready:
		configure()

# Call once from GameWorld._ready()
func configure() -> void:
	# Light properties (guard against missing node)
	if is_instance_valid(sun_light):
		sun_light.light_energy = sun_energy
		sun_light.light_color = sun_color
		sun_light.shadow_enabled = true
		sun_light.shadow_bias = shadow_bias
		sun_light.shadow_normal_bias = shadow_normal_bias

	# Emissive "sun" mesh: create once and assign as override
	if is_instance_valid(visible_sun):
		if _glow_mat == null:
			_glow_mat = StandardMaterial3D.new()
			_glow_mat.emission_enabled = true
			_glow_mat.emission = glow_color
			_glow_mat.emission_energy = glow_energy
			_glow_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
		# apply/refresh current values
		_glow_mat.emission = glow_color
		_glow_mat.emission_energy = glow_energy
		visible_sun.material_override = _glow_mat

	_update_direction()

# ----- UI-facing helpers (keeps UI decoupled from internal sign conventions) -----
func get_ui_elevation_deg() -> float:
	# UI expects 0..180. Internally we store negative for "down".
	return absf(elevation_deg)

func set_ui_elevation_deg(ui_value: float) -> void:
	# UI sends 0..180; keep negative to point down (your preference)
	var clamped := clampf(ui_value, 0.0, 180.0)
	elevation_deg = -clamped
	_update_direction()

func set_ui_azimuth_deg(ui_value: float) -> void:
	# Wrap into [-180,180] to avoid drift if called repeatedly
	azimuth_deg = _wrap_degrees(ui_value)
	_update_direction()

# ----- Programmatic setters -----
func set_distance(dist: float) -> void:
	sun_distance = maxf(0.0, dist)
	_update_direction()

func set_energy(energy: float) -> void:
	sun_energy = maxf(0.0, energy)
	if is_instance_valid(sun_light):
		sun_light.light_energy = sun_energy

func set_color(color: Color) -> void:
	sun_color = color
	if is_instance_valid(sun_light):
		sun_light.light_color = sun_color

# ----- Core math -----
func _update_direction() -> void:
	# Convert spherical (elevation/azimuth) to direction vector
	var elev := deg_to_rad(elevation_deg)
	var azim := deg_to_rad(azimuth_deg)
	var dir := Vector3(
		cos(elev) * cos(azim),
		sin(elev),
		cos(elev) * sin(azim)
	).normalized()

	# Avoid gimbal when nearly vertical
	var up := Vector3.UP
	if absf(dir.dot(Vector3.UP)) > 0.99:
		up = Vector3(0, 0, 1)

	# Aim this rig in the sun direction; child DirectionalLight inherits orientation
	look_at(global_transform.origin + dir, up)

	# Place the visible "sun" mesh at distance along the direction (relative to rig)
	if is_instance_valid(visible_sun):
		visible_sun.global_position = global_transform.origin + dir * sun_distance

# ----- Utils -----
func _wrap_degrees(d: float) -> float:
	# Normalize to [-180, 180]
	return fposmod(d + 180.0, 360.0) - 180.0
