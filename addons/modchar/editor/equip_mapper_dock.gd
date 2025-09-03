# res://addons/modchar/editor/equip_mapper_dock.gd
@tool
extends Control
class_name EquipMapperDock

# Explicitly preload types to avoid any editor/class_name resolution hiccups
@warning_ignore("shadowed_global_identifier")
const EquipSystem  = preload("res://addons/modchar/equip_system.gd")
@warning_ignore("shadowed_global_identifier")
const EquipProfile = preload("res://addons/modchar/equip_profile.gd")
@warning_ignore("shadowed_global_identifier")
const BodyPart     = preload("res://addons/modchar/body_part.gd")

# UI refs
@onready var _pick_btn: Button        = $VBox/Header/PickSkeleton
@onready var _automap_btn: Button     = $VBox/Header/AutoMapMixamo
@onready var _save_btn: Button        = $VBox/Header/SaveProfile
@onready var _viewport: SubViewport   = $VBox/ModelPreview/Viewport
@onready var _mapping_list: ItemList  = $VBox/MappingList

# Editor/plugin state
var _editor: EditorInterface
var _target_system: EquipSystem
var _skeleton: Skeleton3D
var _profile: EquipProfile

func _ready() -> void:
	_pick_btn.pressed.connect(_on_pick_skeleton)
	_automap_btn.pressed.connect(_on_automap)
	_save_btn.pressed.connect(_on_save)
	_refresh_mapping_list()

# Called by modchar_plugin.gd after instantiating the dock
func set_editor(e: EditorInterface) -> void:
	_editor = e

# Called by modchar_plugin.gd when an EquipSystem is selected
func set_target(sys: EquipSystem) -> void:
	_target_system = sys
	_profile = sys.profile if sys else null
	_skeleton = sys._resolve_skeleton() if sys else null
	_load_preview_model()
	_refresh_mapping_list()

# ----- Preview / UI helpers -------------------------------------------------

func _clear_viewport_children() -> void:
	if not _viewport:
		return
	for c in _viewport.get_children():
		(c as Node).queue_free()

func _load_preview_model() -> void:
	_clear_viewport_children()

	if _profile and _profile.model_scene:
		var inst: Node = _profile.model_scene.instantiate()
		_viewport.add_child(inst)
		return

	# Fallback: if we have a skeleton, duplicate its parent branch for a quick preview
	if _skeleton:
		var root: Node = _skeleton.get_parent()
		if root:
			var dup: Node = root.duplicate()  # shallow dup is fine for preview
			_viewport.add_child(dup)

func _refresh_mapping_list() -> void:
	_mapping_list.clear()
	if _profile == null:
		return

	var keys: PackedStringArray = BodyPart.Kind.keys()
	for idx in range(keys.size()):
		var part_name: String = keys[idx]
		var part_id: int = BodyPart.Kind[part_name]
		var bone: String = _profile.get_bone(part_id)
		if bone.is_empty():
			bone = "<unassigned>"
		_mapping_list.add_item("%s → %s" % [part_name, bone])
# ----- Button handlers ------------------------------------------------------

func _on_pick_skeleton() -> void:
	if _editor == null:
		push_warning("EquipMapperDock: EditorInterface not set.")
		return

	var sel: Array = EditorInterface.get_selection().get_selected_nodes()
	if sel.is_empty():
		push_warning("Select a node with an EquipSystem in the scene tree.")
		return

	var node: Node = sel[0]
	var sys: EquipSystem = node as EquipSystem
	if sys == null and node is Node:
		sys = node.get_node_or_null("EquipSystem") as EquipSystem

	if sys == null:
		push_error("No EquipSystem found on the selected node.")
		return

	set_target(sys)

func _on_automap() -> void:
	if _target_system == null:
		push_warning("No EquipSystem selected.")
		return
	_target_system.auto_map_mixamo()
	_profile = _target_system.profile
	_refresh_mapping_list()
	_show_toast("Auto-mapped Mixamo bones.")

func _on_save() -> void:
	if _profile == null:
		push_error("No EquipProfile to save.")
		return

	var dlg := EditorFileDialog.new()
	add_child(dlg)
	dlg.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	dlg.access = EditorFileDialog.ACCESS_RESOURCES
	dlg.add_filter("*.tres ; EquipProfile")

	dlg.file_selected.connect(func(path: String) -> void:
		var err := ResourceSaver.save(_profile, path)
		if err != OK:
			push_error("Failed to save EquipProfile: %s" % error_string(err))
		else:
			_show_toast("Saved EquipProfile → %s" % path)
		dlg.queue_free()
	)
	dlg.canceled.connect(func() -> void:
		dlg.queue_free()
	)

	dlg.popup_centered_ratio(0.5)

# ----- Minimal toast dialog (no EditorNode dependency) ---------------------

func _show_toast(msg: String) -> void:
	var ad := AcceptDialog.new()
	ad.dialog_text = msg
	add_child(ad)
	ad.popup_centered()
	ad.get_ok_button().grab_focus()
