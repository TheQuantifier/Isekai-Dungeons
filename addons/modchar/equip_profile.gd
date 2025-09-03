# res://equip_profile.gd
extends Resource
class_name EquipProfile

@export var model_scene: PackedScene
@export var skeleton_path: NodePath

## Mapping of BodyPart.Kind -> bone name (String)
@export var bodypart_to_bone: Dictionary = {}

## Optional per-socket transform offsets (applied on BoneAttachment3D)
## key: BodyPart.Kind (int) → Transform3D
@export var socket_offsets: Dictionary = {}

func set_mapping(part: int, bone_name: String) -> void:
	bodypart_to_bone[part] = bone_name

func get_bone(part: int) -> String:
	return bodypart_to_bone.get(part, "")

func set_offset(part: int, xf: Transform3D) -> void:
	socket_offsets[part] = xf

func get_offset(part: int) -> Transform3D:
	return socket_offsets.get(part, Transform3D.IDENTITY)

func has_mapping(part: int) -> bool:
	return bodypart_to_bone.has(part) and String(bodypart_to_bone[part]) != ""
