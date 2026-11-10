extends Node

signal progress_reset

const SAVE_PATH = "user://save.cfg"

var tutorial_done := false
var unlocked_level := 1
var total_coins := 0        # lifetime coins, banked when you finish a level
var best_coins := {}        # level_number -> most coins grabbed in one run
var owned_items: Array[String] = []   # resource paths of picked up items
var upgrades := {}          # upgrade id (String) -> level, see Upgrades autoload
var found_pickups: Array[String] = []   # "scene::node" of collected UpgradePickups

func _ready() -> void:
	load_game()

func save_game() -> void:
	var cfg = ConfigFile.new()
	cfg.set_value("progress", "tutorial_done", tutorial_done)
	cfg.set_value("progress", "unlocked_level", unlocked_level)
	cfg.set_value("coins", "total", total_coins)
	cfg.set_value("coins", "best", best_coins)
	cfg.set_value("items", "owned", owned_items)
	cfg.set_value("upgrades", "levels", upgrades)
	cfg.set_value("upgrades", "found", found_pickups)
	cfg.save(SAVE_PATH)

func load_game() -> void:
	var cfg = ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return   # no save yet = first time playing
	tutorial_done = cfg.get_value("progress", "tutorial_done", false)
	unlocked_level = cfg.get_value("progress", "unlocked_level", 1)
	total_coins = cfg.get_value("coins", "total", 0)
	best_coins = cfg.get_value("coins", "best", {})
	owned_items.assign(cfg.get_value("items", "owned", []))
	upgrades = cfg.get_value("upgrades", "levels", {})
	found_pickups.assign(cfg.get_value("upgrades", "found", []))

# called when a level is finished
func bank_coins(level: int, amount: int) -> void:
	total_coins += amount
	best_coins[level] = max(best_coins.get(level, 0), amount)
	save_game()

func reset() -> void:
	tutorial_done = false
	unlocked_level = 1
	total_coins = 0
	best_coins = {}
	owned_items.clear()
	upgrades = {}
	found_pickups.clear()
	save_game()
	progress_reset.emit()
