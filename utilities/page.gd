extends Node
class_name Page   # importable everywhere

const LOGIN = "res://ui/login_page/login_page.tscn"
const MAIN_MENU = "res://ui/main_menu/main_menu.tscn"
const GAME_WORLD = "res://scenes/game_world/game_world.tscn"
const CHARACTER_CUSTOMIZATION = "res://scenes/character_customization/character_customization.tscn"
const STATS = "res://ui/stats_view/stats_view.tscn"
const LOADING = "res://ui/loading_scene/loading.tscn"
const SETTINGS = "res://ui/settings/settings_old.tscn"
const INVENTORY = "res://ui/stats_view/stats_view.tscn"

# Optional: keep a name→path map for string callers
const BY_NAME := {
	"LOGIN": LOGIN,
	"MAIN_MENU": MAIN_MENU,
	"GAME_WORLD": GAME_WORLD,
	"CHARACTER_CUSTOMIZATION": CHARACTER_CUSTOMIZATION,
	"STATS": STATS,
	"LOADING": LOADING,
	"SETTINGS": SETTINGS,
	"INVENTORY": INVENTORY,
}

static func from_name(path_name: String) -> String:
	return BY_NAME.get(path_name, "")
