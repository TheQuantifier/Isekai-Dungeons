# res://core/config/player_settings.gd
# Defaults only — edit the .tres (player_settings.tres), not this script.
extends Resource
class_name PlayerSettings

# =========================
# Movement
# =========================
@export_category("Movement")

@export_group("Land")
@export var move_speed: float = 10.0
@export var sprint_speed: float = 20.0
@export var crouch_speed: float = 4.0
@export var airborne_speed: float = 4.0
@export var jump_velocity: float = 14.0
@export var turn_speed: float = 2.0
@export var gravity: float = 40.0

@export_group("Water")
@export var water_speed: float = 4.0
@export var water_sprint_speed: float = 20.0
@export var water_turn_speed: float = 1.0

@export_group("Water Surface")
@export var water_surface_height: float = -5.0
@export var surface_offset: float = -0.8

@export_group("Surface Hold & Bob")
@export var enable_surface_hold: bool = true
@export var enable_bob: bool = true
@export var bob_height: float = 0.2
@export var bob_speed: float = 0.5
@export var bob_follow_accel: float = 12.0
@export var bob_max_speed: float = 6.0
@export var water_sink_accel: float = 3.0
@export var max_sink_speed: float = 3.0

# =========================
# Animation
# =========================
@export_category("Animation")

@export_group("Land Speed Scaling")
@export var anim_idle: float = 1.0
@export var anim_run: float = 1.0
@export var anim_run_backward: float = 1.0
@export var anim_sprint: float = 1.5
@export var anim_sprint_backward: float = 2.0
@export var anim_crouch_idle: float = 1.0
@export var anim_crouch_run: float = 1.0
@export var anim_crouch_run_backward: float = 1.0
@export var anim_jump: float = 1.5
@export var anim_jump_stat: float = 2.75

@export_group("Water Speed Scaling")
@export var anim_swim: float = 1.0
@export var anim_swim_sprint: float = 1.5
@export var anim_treading: float = 1.0   # playback speed while treading at surface

@export_group("Smoothing")
@export var anim_smoothness: float = 0.09
