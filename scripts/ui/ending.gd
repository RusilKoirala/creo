extends Control

const FONT = preload("res://assets/fonts/PixelOperator8-Bold.ttf")

const LINES := [
	["thank you for playing the game", 28, 0.0],
	["i hope you loved it :D", 22, 1.2],
	["", 22, 0.0],
	["", 22, 0.0],
	["made by @rusilkoirala", 16, 2.0],
]

var leaving := false
var can_skip := false
var box: VBoxContainer
var hint: Label


func _ready() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0

	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	box = VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	add_child(box)

	var labels: Array[Label] = []
	for l in LINES:
		var lbl := _label(l[0], l[1])
		lbl.modulate.a = 0.0
		box.add_child(lbl)
		labels.append(lbl)

	hint = _label("press any key", 10)
	hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint.position.y -= 40
	hint.modulate = Color(1, 1, 1, 0)
	add_child(hint)

	box.position.y += 20
	create_tween().tween_property(box, "position:y", box.position.y - 20, 6.0) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	await get_tree().create_timer(1.0).timeout
	for i in labels.size():
		if LINES[i][0] == "":
			continue
		await get_tree().create_timer(LINES[i][2]).timeout
		create_tween().tween_property(labels[i], "modulate:a", 1.0, 1.4)

	await get_tree().create_timer(2.0).timeout
	can_skip = true
	var t := create_tween().set_loops()
	t.tween_property(hint, "modulate:a", 0.6, 1.0)
	t.tween_property(hint, "modulate:a", 0.15, 1.0)

	await get_tree().create_timer(10.0).timeout
	_leave()


func _label(text: String, size: int) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", FONT)
	lbl.add_theme_font_size_override("font_size", size)
	return lbl


func _unhandled_input(event: InputEvent) -> void:
	if not can_skip:
		return
	if (event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton) and event.pressed:
		_leave()


func _leave() -> void:
	if leaving:
		return
	leaving = true
	SceneChanger.change_scene("res://scenes/ui/main_menu.tscn")
