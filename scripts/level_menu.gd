extends Control

# Button order on screen -> level number. Add a path here when you make a new level.
const LEVELS := {
	1: "res://sences/level/level1.tscn",
}

func _ready() -> void:
	var buttons := []
	buttons.append_array($Node2D.get_children())
	buttons.append_array($Node2D2.get_children())

	for i in buttons.size():
		var btn: Button = buttons[i]
		var level := i + 1
		var exists := LEVELS.has(level)
		var unlocked := level <= SaveData.unlocked_level
		btn.disabled = not (exists and unlocked)
		if btn.disabled:
			btn.modulate = Color(1, 1, 1, 0.4)
		btn.pressed.connect(_on_level_pressed.bind(level))

func _on_level_pressed(level: int) -> void:
	SceneChanger.change_scene(LEVELS[level])

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		SceneChanger.change_scene("res://sences/main_menu.tscn")
