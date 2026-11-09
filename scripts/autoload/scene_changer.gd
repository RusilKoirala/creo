extends CanvasLayer

var rect: ColorRect

func _ready() -> void:
	layer = 100
	rect = ColorRect.new()
	rect.color = Color.BLACK
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.modulate.a = 0.0
	add_child(rect)

func change_scene(path: String) -> void:
	var tween = create_tween()
	tween.tween_property(rect, "modulate:a", 1.0, 0.5)
	await tween.finished
	get_tree().change_scene_to_file(path)
	tween = create_tween()
	tween.tween_property(rect, "modulate:a", 0.0, 0.5)
