extends Control


func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://sences/level/training_level.tscn")





func _on_button_option_pressed() -> void:
	pass # Option Menu


func _on_button_exit_pressed() -> void:
	get_tree().quit()
