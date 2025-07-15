# res://scenes/game_world/GameWorld.gd
extends Node3D

@onready var player: CharacterBody3D = $Player
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D

@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	var player_transform = player.global_transform
	
	# Offset behind and above the player, based on their forward direction
	var back_offset = -player_transform.basis.z.normalized() * 3.5  # 2 units behind
	var up_offset = Vector3.UP * 2.0                               # 2 units up
	var camera_position = player_transform.origin + back_offset + up_offset
	
	camera_pivot.global_position = camera_position
	camera.look_at(player_transform.origin, Vector3.UP)


func _on_main_menu_pressed() -> void:
	game_manager.go_to_main_menu()
