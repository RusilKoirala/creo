extends Area2D

@onready var timer = $Timer
@export var completes_tutorial := false
@export var level_number := 0  

var done := false

func _on_body_entered(body: Node2D) -> void:
	if done:
		return
	done = true
	timer.start()


func _on_timer_timeout() -> void:
	var level := _current_level()
	var gm = get_tree().current_scene.get_node_or_null("GameManager")
	if gm:
		SaveData.bank_coins(level, gm.score)
	SaveData.tutorial_done = true
	# beating a level unlocks the next one
	SaveData.unlocked_level = max(SaveData.unlocked_level, level + 1)
	SaveData.save_game()
	SceneChanger.change_scene("res://scenes/ui/level_menu.tscn")


# Level number comes from the file name (level2.tscn -> 2), so you never
# have to set it by hand. Falls back to level_number for other scenes.
func _current_level() -> int:
	var file := get_tree().current_scene.scene_file_path.get_file()
	var m := RegEx.create_from_string("^level(\\d+)\\.tscn$").search(file)
	if m:
		return int(m.get_string(1))
	return level_number
