# res://core/character/backpack.gd
extends Inventory
class_name Backpack

var character_owner: Character = null

func _init(_max_size: int = 30, _character_owner: Character = null) -> void:
	max_size = _max_size
	character_owner = _character_owner
