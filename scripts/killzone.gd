extends Area2D

@onready var timer = $Timer
@onready var player_anim = $AnimatedSprite2D

func _on_body_entered(body: Node2D) -> void:
	
	print("you died")
	timer.start()



func _on_timer_timeout() -> void:
	get_tree().reload_current_scene()
	
