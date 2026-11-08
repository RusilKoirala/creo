extends Node

const SAVE_PATH = "user://save.cfg"

var tutorial_done := false
var unlocked_level := 1  

func _ready() -> void:
	load_game()

func save_game() -> void:
	var cfg = ConfigFile.new()
	cfg.set_value("progress", "tutorial_done", tutorial_done)
	cfg.set_value("progress", "unlocked_level", unlocked_level)
	cfg.save(SAVE_PATH)

func load_game() -> void:
	var cfg = ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return   # no save yet = first time playing
	tutorial_done = cfg.get_value("progress", "tutorial_done", false)
	unlocked_level = cfg.get_value("progress", "unlocked_level", 1)

func reset() -> void:
	tutorial_done = false
	unlocked_level = 1
	save_game()
