# res://addons/modchar/modchar_plugin.gd
@tool
extends EditorPlugin

var dock: EquipMapperDock

func _enter_tree() -> void:
	# Register EquipSystem as a custom node type
	add_custom_type(
		"EquipSystem",
		"Node3D",
		preload("res://addons/modchar/equip_system.gd"),
		preload("res://addons/modchar/icon.svg")
	)

	# Add the editor dock panel
	dock = preload("res://addons/modchar/editor/equip_mapper_dock.tscn").instantiate()
	dock.set_editor(get_editor_interface())
	add_control_to_bottom_panel(dock, "ModChar Mapper")

func _exit_tree() -> void:
	if dock:
		remove_control_from_bottom_panel(dock)
		dock.free()
		dock = null
	remove_custom_type("EquipSystem")

# Make the dock follow selection of an EquipSystem
func _handles(object: Object) -> bool:
	return object is EquipSystem

func _edit(object: Object) -> void:
	if object is EquipSystem and dock:
		dock.set_target(object)
