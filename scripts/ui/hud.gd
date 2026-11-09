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


# ---- "Got <item>!" popup (the Toast label lives in hud.tscn) ----
@onready var toast: Label = $Toast

func _enter_tree() -> void:
	Inventory.item_added.connect(_on_item_added)

func _exit_tree() -> void:
	Inventory.item_added.disconnect(_on_item_added)

func _on_item_added(item: ItemData) -> void:
	toast.text = "Got %s!\n%s" % [item.display_name, item.description]
	toast.show()
	toast.pivot_offset = toast.size / 2
	toast.modulate.a = 1.0
	toast.scale = Vector2(0.5, 0.5)
	var t := create_tween()
	t.tween_property(toast, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(2.5)
	t.tween_property(toast, "modulate:a", 0.0, 0.5)
	t.tween_callback(toast.hide)
