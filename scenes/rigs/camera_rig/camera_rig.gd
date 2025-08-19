# res://scenes/rigs/camera_rig/camera_rig.gd
extends Node3D
class_name CameraRig

@onready var pivot: Node3D = $Pivot
@onready var cam_third: Camera3D = $Pivot/Third
@onready var cam_first: Camera3D = $Pivot/First

# --- Placement / offsets ---
@export var third_person_back: float = 3.5
@export var third_person_up: float = 2.0
@export var first_person_head_height: float = 1.6
@export var first_person_forward_offset: float = 0.2
@export var default_fov: float = 75.0

# --- Camera look (auto-exposure lives on CameraAttributes in Godot 4.x) ---
@export var use_auto_exposure: bool = false
@export var auto_exposure_min_iso: float = 100.0
@export var auto_exposure_max_iso: float = 1600.0
@export var auto_exposure_speed: float = 0.5
@export var auto_exposure_scale: float = 1.0

# Optional: drag a CameraAttributes resource in the inspector. If null, we create one.
@export var camera_attributes: CameraAttributes

func configure() -> void:
	# reset rotations/FOV
	if cam_first:
		cam_first.rotation = Vector3.ZERO
		cam_first.fov = default_fov
	if cam_third:
		cam_third.rotation = Vector3.ZERO
		cam_third.fov = default_fov

	# ensure attributes exist and apply to both cameras
	_ensure_attributes()
	_apply_attributes()

func update_follow(player: Node3D, is_first_person: bool) -> void:
	if player == null:
		return

	var t := player.global_transform
	var forward := t.basis.z.normalized()
	var head := Vector3.UP * first_person_head_height

	if is_first_person:
		# first-person: eye level, slight forward offset
		pivot.global_position = t.origin + head + Vector3(0, 0.75, 0) + forward * first_person_forward_offset
		pivot.rotation.y = player.rotation.y + PI
		if cam_first: cam_first.current = true
		if cam_third: cam_third.current = false
		return

	# third-person: over-the-shoulder
	pivot.global_position = t.origin - forward * third_person_back + Vector3.UP * third_person_up
	if cam_third:
		cam_third.look_at(t.origin + Vector3.UP * 1.5, Vector3.UP)
		cam_third.current = true
	if cam_first:
		cam_first.current = false

# --- Public helpers (nice for settings menus) ---

func set_fov(deg: float) -> void:
	default_fov = deg
	if cam_first: cam_first.fov = deg
	if cam_third: cam_third.fov = deg

func set_auto_exposure_enabled(enabled: bool) -> void:
	use_auto_exposure = enabled
	_apply_attributes()

func set_auto_exposure_iso_range(min_iso: float, max_iso: float) -> void:
	auto_exposure_min_iso = min_iso
	auto_exposure_max_iso = max_iso
	_apply_attributes()

func set_auto_exposure_speed_scale(speed: float, exposure_scale: float) -> void:
	auto_exposure_speed = speed
	auto_exposure_scale = exposure_scale
	_apply_attributes()

# --- Internals ---

func _ensure_attributes() -> void:
	if camera_attributes == null:
		# Use Practical; Physical also works if you prefer physical units.
		camera_attributes = CameraAttributesPractical.new()
	# assign to both cameras
	if cam_first: cam_first.attributes = camera_attributes
	if cam_third: cam_third.attributes = camera_attributes

func _apply_attributes() -> void:
	_ensure_attributes()
	var attrs := camera_attributes
	if attrs == null:
		return

	# Correct fields for CameraAttributesPractical in Godot 4.4.1
	attrs.auto_exposure_enabled = use_auto_exposure
	attrs.auto_exposure_min_sensitivity = auto_exposure_min_iso
	attrs.auto_exposure_max_sensitivity = auto_exposure_max_iso
	attrs.auto_exposure_speed = auto_exposure_speed
	attrs.auto_exposure_scale = auto_exposure_scale
