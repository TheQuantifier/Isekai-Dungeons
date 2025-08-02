extends Resource
class_name Skill

@export var name: String
@export var description: String
@export var mana_cost: int = 5
@export var cooldown: float = 3.0
@export var level: int = 1

func use(caster: Character, _target: Character) -> String:
	return "%s used %s!" % [caster.char_id, name]

func level_up() -> void:
	level += 1
