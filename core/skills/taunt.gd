extends "res://core/skills/skill.gd"

func _init():
	name = "Taunt"
	description = "Force enemies to target you. Higher levels increase aggro duration."
	mana_cost = 4
	cooldown = 5.0
	level = 1

func use(caster: Character, target: Character) -> String:
	if caster.current_mana < mana_cost:
		return "%s doesn’t have enough mana to use Taunt!" % caster.char_id

	caster.add_mana(-mana_cost)

	var aggro_duration = 3 + level  # 3 seconds base, +1 sec per level

	# Example: pretend to call a method that applies aggro logic
	if target.has_method("apply_aggro"):
		target.apply_aggro(caster, aggro_duration)

	return "%s uses Taunt (Lv.%d) on %s! Aggro for %d seconds." % [
		caster.char_id, level, target.char_id, aggro_duration
	]
