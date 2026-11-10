extends Area2D
@onready var game_manager = $"../../GameManager"
@onready var coin_sound = $CoinSound

func _on_body_entered(body: Node2D) -> void:
	set_deferred("monitoring", false)
	Checkpoint.note_coin(self)
	game_manager.add_score()
	coin_sound.pitch_scale = randf_range(0.9, 1.2)
	coin_sound.play()

	# pop up and fade instead of just vanishing
	var t := create_tween().set_parallel()
	t.tween_property(self, "position:y", position.y - 14, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "scale", Vector2(1.6, 1.6), 0.15)
	t.tween_property(self, "modulate:a", 0.0, 0.25).set_delay(0.12)

	await coin_sound.finished
	queue_free()
