extends Control

@export var target_scene_path: String = "res://scenes/game_world/game_world.tscn"

func _ready():
	await get_tree().process_frame

	# Start async loading of the next scene
	var _resource_loader := ResourceLoader.load_threaded_request(target_scene_path)

	# Wait until loading is complete
	while ResourceLoader.load_threaded_get_status(target_scene_path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame

	# Once loaded, route scene change through GameManager
	var loaded := ResourceLoader.load_threaded_get(target_scene_path)
	if loaded:
		game_manager.current_scene_path = target_scene_path
		game_manager.get_tree().change_scene_to_packed(loaded)
