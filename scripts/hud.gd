extends CanvasLayer

@onready var bar = $HealthBar

func _ready() -> void:
	var player = get_parent()
	player.health_changed.connect(_on_health_changed)

func _on_health_changed(current: int, max_value: int) -> void:
	print("health: ", current, " / ", max_value)
	bar.max_value = max_value
	bar.value = current
