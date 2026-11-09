extends RefCounted

# Shared look for menus so main menu, options and pause all match.

const FONT = preload("res://assets/fonts/PixelOperator8-Bold.ttf")

const YELLOW = Color(1, 0.86, 0.2)
const ORANGE = Color(1, 0.6, 0.15)
const DARK = Color(0.12, 0.1, 0.16)


static func box(color: Color, radius := 12, shadow := 5) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	s.corner_detail = 8
	s.shadow_size = shadow
	s.shadow_offset = Vector2(0, shadow)
	s.shadow_color = Color(0, 0, 0, 0.35)
	s.set_content_margin_all(10)
	return s


# Big chunky button with hover/press feel + click sound.
static func button(text: String, font_size := 28) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(320, 64)
	b.add_theme_font_override("font", FONT)
	b.add_theme_font_size_override("font_size", font_size)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, DARK)
	b.add_theme_color_override("font_disabled_color", Color(0, 0, 0, 0.4))
	b.add_theme_stylebox_override("normal", box(YELLOW))
	b.add_theme_stylebox_override("hover", box(ORANGE))
	b.add_theme_stylebox_override("pressed", box(ORANGE.darkened(0.15), 12, 1))
	b.add_theme_stylebox_override("focus", box(Color(0, 0, 0, 0), 12, 0))
	b.add_theme_stylebox_override("disabled", box(Color(0.6, 0.6, 0.6)))
	add_juice(b)
	return b


# Scale up on hover, squish on press, click sound.
static func add_juice(b: Button) -> void:
	b.resized.connect(func(): b.pivot_offset = b.size / 2)
	b.mouse_entered.connect(func():
		if b.disabled: return
		b.create_tween().tween_property(b, "scale", Vector2(1.06, 1.06), 0.08))
	b.mouse_exited.connect(func():
		b.create_tween().tween_property(b, "scale", Vector2.ONE, 0.08))
	b.button_down.connect(func():
		b.scale = Vector2(0.94, 0.94))
	b.pressed.connect(func():
		Settings.click()
		b.create_tween().tween_property(b, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))


static func label(text: String, font_size := 24, color := Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", 4)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


# Pop a list of controls in one after another.
static func pop_in(nodes: Array, delay_step := 0.06) -> void:
	for i in nodes.size():
		var n: Control = nodes[i]
		n.modulate.a = 0.0
		var t := n.create_tween().set_parallel()
		t.tween_property(n, "modulate:a", 1.0, 0.2).set_delay(i * delay_step)
		t.tween_property(n, "position:y", n.position.y, 0.25).from(n.position.y + 20) \
			.set_delay(i * delay_step).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
