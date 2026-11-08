extends Area2D

@onready var timer = $Timer
@export var completes_tutorial := false
@export var level_number := 0   # 0 = training, 1 = level 1, ...

var done := false

func _on_body_entered(body: Node2D) -> void:
	if done:
		return
	done = true
	timer.start()


func _on_timer_timeout() -> void:
	SaveData.tutorial_done = true
	# beating a level unlocks the next one
	SaveData.unlocked_level = max(SaveData.unlocked_level, level_number + 1)
	SaveData.save_game()
	SceneChanger.change_scene("res://sences/level/level_menu.tscn")
