# res://core/stats/stat_types.gd
extends Node
class_name StatTypes

enum StrengthType { PHYSICAL, MAGICAL, TECHNICAL }
enum DefenseType { HEAD, CHEST, LEG, FEET, SHIELD }
enum ResistanceType { PHYSICAL, MAGICAL }

# ----- Character Data Enums -----#
enum ClassType {
	NONE,
	WARRIOR,
	TANK,
	MAGE,
	HEALER,
	ROGUE,
	ARCHER,
	SUMMONER,
	ENCHANTER
}

enum Gender { MALE, FEMALE }
