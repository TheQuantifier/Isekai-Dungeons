extends "res://core/skills/skill.gd"

func _init():
	name = "Fireball"
	description = "Launch a fireball to burn your target."
	mana_cost = 5
	cooldown = 2.0
	level = 1

func use(caster: Character, target: Character) -> String:
	if caster.current_mana < mana_cost:
		return "%s doesn’t have enough mana to cast Fireball!" % caster.char_id

	var damage = 10 + level * 5
	caster.add_mana(-mana_cost)
	target.add_health(-damage)

	return "%s casts Fireball (Lv.%d) on %s for %d damage!" % [caster.char_id, level, target.char_id, damage]
