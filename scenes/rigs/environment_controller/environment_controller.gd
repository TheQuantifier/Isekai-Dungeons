# res://scenes/rigs/environment_controller/environment_controller.gd
extends Node
class_name EnvironmentController

@onready var world_env: WorldEnvironment = $WorldEnvironment

@export var exposure: float = 1.5
@export var ambient_energy: float = 0.5
@export var ambient_sky: float = 0.5

@export var glow_enabled: bool = true
@export var ssr_enabled: bool = false
@export var ssao_enabled: bool = true
@export var sdfgi_enabled: bool = false  # Godot 4.x SDFGI

@export var create_env_if_missing: bool = false  # handy for hot-reloads

func _env() -> Environment:
	if world_env == null:
		return null
	if world_env.environment == null and create_env_if_missing:
		world_env.environment = Environment.new()
	return world_env.environment

func configure() -> void:
	var env := _env()
	if env == null:
		push_warning("EnvironmentController: Missing WorldEnvironment or Environment resource.")
		return

	env.adjustment_enabled = true
	env.tonemap_exposure = exposure
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.ambient_light_energy = ambient_energy
	env.ambient_light_sky_contribution = ambient_sky

	env.glow_enabled = glow_enabled
	env.ssr_enabled  = ssr_enabled
	env.ssao_enabled = ssao_enabled
	env.sdfgi_enabled = sdfgi_enabled

func set_exposure(value: float) -> void:
	exposure = value
	var env := _env()
	if env != null:
		env.tonemap_exposure = exposure

func set_ambient(energy: float, sky_contrib: float) -> void:
	ambient_energy = energy
	ambient_sky = sky_contrib
	var env := _env()
	if env != null:
		env.ambient_light_energy = ambient_energy
		env.ambient_light_sky_contribution = ambient_sky

# --- Optional runtime toggles (nice for settings menus) ---
func set_glow_enabled(enabled: bool) -> void:
	glow_enabled = enabled
	var env := _env()
	if env != null:
		env.glow_enabled = glow_enabled

func set_ssr_enabled(enabled: bool) -> void:
	ssr_enabled = enabled
	var env := _env()
	if env != null:
		env.ssr_enabled = ssr_enabled

func set_ssao_enabled(enabled: bool) -> void:
	ssao_enabled = enabled
	var env := _env()
	if env != null:
		env.ssao_enabled = ssao_enabled

func set_sdfgi_enabled(enabled: bool) -> void:
	sdfgi_enabled = enabled
	var env := _env()
	if env != null:
		env.sdfgi_enabled = sdfgi_enabled
