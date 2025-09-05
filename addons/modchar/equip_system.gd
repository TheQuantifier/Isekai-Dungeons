# res://addons/modchar/equip_system.gd
@tool
extends Node3D
class_name EquipSystem

# These are in the same folder as this script (res://addons/modchar/)
@warning_ignore("shadowed_global_identifier")
const BodyPart     = preload("body_part.gd")
@warning_ignore("shadowed_global_identifier")
const EquipProfile = preload("equip_profile.gd")

## Equip/unequip meshes to skeleton bones, using a high-level BodyPart map.
## Attachments are created as BoneAttachment3D children of the Skeleton3D.

@export var profile: EquipProfile
@export_node_path("Skeleton3D") var skeleton_path: NodePath

@onready var _skeleton: Skeleton3D = _resolve_skeleton()

signal equipped(part: int, node: Node)
signal unequipped(part: int, node: Node)

const SOCKET_PREFIX := "equip_socket_"   # final names like equip_socket_HEAD


func _resolve_skeleton() -> Skeleton3D:
	# If explicitly set, use it.
	if skeleton_path != NodePath(""):
		var n := get_node_or_null(skeleton_path)
		return n as Skeleton3D

	# Search downward (deep) from self
	var s := _find_skeleton_in_subtree(self)
	if s:
		return s

	# Walk upwards and scan each ancestor's subtree
	var p := get_parent()
	while p and not s:
		if p is Skeleton3D:
			return p
		s = _find_skeleton_in_subtree(p)
		p = p.get_parent()
	return s


func _find_skeleton_in_subtree(n: Node) -> Skeleton3D:
	for c in n.get_children():
		if c is Skeleton3D:
			return c
		var deeper := _find_skeleton_in_subtree(c)
		if deeper:
			return deeper
	return null


func ready_profile_defaults() -> void:
	if profile == null:
		profile = EquipProfile.new()
	if _skeleton == null:
		_skeleton = _resolve_skeleton()
	if _skeleton and profile.skeleton_path == NodePath(""):
		profile.skeleton_path = _skeleton.get_path()


func get_socket_name(part: int) -> String:
	# Coerce enum key to String to satisfy static typing
	var part_name: String = String(BodyPart.Kind.keys()[part])
	return SOCKET_PREFIX + part_name


func _ensure_socket(part: int) -> BoneAttachment3D:
	assert(_skeleton, "EquipSystem: No Skeleton3D found.")
	var socket_name: String = get_socket_name(part)

	var ba := _skeleton.get_node_or_null(socket_name)
	if not (ba is BoneAttachment3D):
		ba = BoneAttachment3D.new()
		ba.name = socket_name
		_skeleton.add_child(ba)
		if Engine.is_editor_hint():
			ba.owner = get_tree().edited_scene_root

	# Bind to mapped bone if available
	if profile and profile.has_mapping(part):
		var bone_name: String = profile.get_bone(part)
		var bone_idx: int = _skeleton.find_bone(bone_name)
		if bone_idx >= 0:
			(ba as BoneAttachment3D).bone_name = bone_name

	# Apply optional offset
	if profile and profile.socket_offsets.has(part):
		(ba as BoneAttachment3D).transform = profile.get_offset(part)

	return ba as BoneAttachment3D


## Public API ---------------------------------------------------------------

## Equip a PackedScene or Node3D under the socket for the given BodyPart.Kind.
## If an item already exists under that socket, it will be replaced.
func equip(item: Variant, part: int) -> Node3D:
	if _skeleton == null:
		_skeleton = _resolve_skeleton()
	if _skeleton == null:
		push_error("EquipSystem.equip: No Skeleton3D available.")
		return null

	var socket := _ensure_socket(part)

	# Clear existing
	for child in socket.get_children():
		socket.remove_child(child)
		unequipped.emit(part, child)
		(child as Node).queue_free()

	var node: Node3D = null
	if item is PackedScene:
		node = (item as PackedScene).instantiate()
	elif item is Node3D:
		node = item
	else:
		push_error("EquipSystem.equip: item must be PackedScene or Node3D")
		return null

	socket.add_child(node)
	if Engine.is_editor_hint():
		node.owner = get_tree().edited_scene_root

	# If it's a MeshInstance3D with a Skin, bind it to skeleton for deformation armor
	if node is MeshInstance3D:
		var mi: MeshInstance3D = node as MeshInstance3D
		if mi.skin:
			mi.skeleton = _skeleton.get_path()

	equipped.emit(part, node)
	return node


## Remove any equipped node from the socket.
func unequip(part: int) -> void:
	if _skeleton == null:
		return
	var socket_name: String = get_socket_name(part)
	var socket := _skeleton.get_node_or_null(socket_name)
	if not (socket is BoneAttachment3D):
		return
	var ba: BoneAttachment3D = socket as BoneAttachment3D
	for child in ba.get_children():
		ba.remove_child(child)
		unequipped.emit(part, child)
		(child as Node).queue_free()


## Returns the current equipped node for a part, if any.
func get_equipped(part: int) -> Node3D:
	if _skeleton == null:
		return null
	var socket_name: String = get_socket_name(part)
	var socket := _skeleton.get_node_or_null(socket_name)
	if socket is BoneAttachment3D and socket.get_child_count() > 0:
		return socket.get_child(0) as Node3D
	return null


## Debug helper to auto-map common Mixamo bones if profile is empty.
func auto_map_mixamo() -> void:
	if _skeleton == null:
		_skeleton = _resolve_skeleton()
	if _skeleton == null:
		return
	if profile == null:
		profile = EquipProfile.new()

	var map := {
		BodyPart.Kind.HEAD: "Head",
		BodyPart.Kind.NECK: "Neck",
		BodyPart.Kind.CHEST: "Spine2",
		BodyPart.Kind.BACK: "Spine2",
		BodyPart.Kind.HIPS: "Hips",
		BodyPart.Kind.LEFT_SHOULDER: "LeftShoulder",
		BodyPart.Kind.RIGHT_SHOULDER: "RightShoulder",
		BodyPart.Kind.LEFT_HAND: "LeftHand",
		BodyPart.Kind.RIGHT_HAND: "RightHand",
		BodyPart.Kind.LEFT_FOOT: "LeftFoot",
		BodyPart.Kind.RIGHT_FOOT: "RightFoot",
	}

	for k in map.keys():
		var bone_name: String = map[k]
		if _skeleton.find_bone(bone_name) >= 0:
			profile.set_mapping(k, bone_name)
