extends CanvasLayer

@onready var bar = $HealthBar

var first := true

func _ready() -> void:
	var player = get_parent()
	player.health_changed.connect(_on_health_changed)

func _on_health_changed(current: int, max_value: int) -> void:
	print("health: ", current, " / ", max_value)
	bar.max_value = max_value
	if first:
		bar.value = current
		first = false
		return

	# slide the bar instead of snapping, and wiggle it on damage
	create_tween().tween_property(bar, "value", current, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if current < bar.value:
		var base: Vector2 = bar.position
		var t := create_tween()
		for i in 4:
			t.tween_property(bar, "position", base + Vector2(randf_range(-4, 4), randf_range(-3, 3)), 0.04)
		t.tween_property(bar, "position", base, 0.04)
