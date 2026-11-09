extends AnimatedSprite2D

## Plays its animation once and removes itself. Use for hit sparks etc.

func _ready() -> void:
	animation_finished.connect(queue_free)
	play()
