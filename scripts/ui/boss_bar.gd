class_name BossBar
extends CanvasLayer

## Big health bar at the top of the screen. The BossArena makes one when the
## fight starts: BossBar.create(boss_name, max_hp) and calls set_health().

const UI = preload("res://scripts/ui/ui_style.gd")

const COLOR_P1 := Color(0.85, 0.2, 0.3)
const COLOR_P2 := Color(0.7, 0.25, 0.95)

var root: Control
var name_label: Label
var fill: ProgressBar
var trail: ProgressBar
var fill_style: StyleBoxFlat
var max_hp := 1


static func create(boss_name: String, hp: int) -> BossBar:
	var b := BossBar.new()
	b.max_hp = hp
	b._build(boss_name)
	return b


func _build(boss_name: String) -> void:
	layer = 20
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_CENTER_TOP)
	root.offset_left = -300
	root.offset_right = 300
	root.offset_top = 24
	root.offset_bottom = 90
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	name_label = UI.label(boss_name.to_upper(), 22, Color(1, 0.9, 1))
	name_label.add_theme_color_override("font_outline_color", UI.DARK)
	name_label.add_theme_constant_override("outline_size", 8)
	name_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	root.add_child(name_label)

	var frame := Panel.new()
	var fs := UI.box(UI.DARK, 6, 4)
	fs.border_color = Color(1, 0.9, 1, 0.9)
	fs.set_border_width_all(3)
	frame.add_theme_stylebox_override("panel", fs)
	frame.position = Vector2(0, 34)
	frame.size = Vector2(600, 28)
	root.add_child(frame)

	trail = _bar(Color(1, 0.95, 0.85))
	fill = _bar(COLOR_P1)
	fill_style = fill.get_theme_stylebox("fill")
	for b in [trail, fill]:
		b.position = Vector2(5, 39)
		b.size = Vector2(590, 18)
		root.add_child(b)

	# slide in from the top
	root.modulate.a = 0.0
	var t := root.create_tween().set_parallel()
	t.tween_property(root, "modulate:a", 1.0, 0.4)
	t.tween_property(root, "position:y", root.position.y, 0.5).from(root.position.y - 60) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _bar(color: Color) -> ProgressBar:
	var b := ProgressBar.new()
	b.show_percentage = false
	b.max_value = max_hp
	b.value = max_hp
	b.add_theme_stylebox_override("background", StyleBoxEmpty.new())
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(3)
	b.add_theme_stylebox_override("fill", s)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


func set_health(current: int, _max := -1) -> void:
	current = maxi(current, 0)
	fill.value = current
	var t := create_tween()
	t.tween_interval(0.35)
	t.tween_property(trail, "value", current, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	# little jolt
	var home := 24.0
	var j := root.create_tween()
	j.tween_property(root, "offset_top", home + 3, 0.04)
	j.tween_property(root, "offset_top", home, 0.08)


func enter_phase_two() -> void:
	fill_style.bg_color = COLOR_P2
	name_label.text = name_label.text + "  - ENRAGED"
	name_label.pivot_offset = name_label.size / 2
	name_label.scale = Vector2(1.3, 1.3)
	create_tween().tween_property(name_label, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func defeated() -> void:
	name_label.text = "DEFEATED"
	name_label.add_theme_color_override("font_color", UI.YELLOW)
	var t := root.create_tween()
	t.tween_interval(2.0)
	t.tween_property(root, "modulate:a", 0.0, 0.8)
	t.tween_callback(queue_free)
