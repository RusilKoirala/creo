extends Area2D
@onready var game_manager = $"../../GameManager"
@onready var coin_sound = $CoinSound

func _on_body_entered(body: Node2D) -> void:
	hide()                
	game_manager.add_score()                 
	set_deferred("monitoring", false)      
	coin_sound.play()
	await coin_sound.finished
	queue_free()
