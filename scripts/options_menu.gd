extends Control

# Options screen built in code. Used by main menu and pause menu:
#   var o = OptionsMenu.new(); add_child(o); o.closed.connect(...)

signal closed

const UI = preload("res://scripts/ui_style.gd")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	var style := UI.box(UI.DARK, 18, 8)
	style.set_content_margin_all(32)
	style.border_color = UI.YELLOW
	style.set_border_width_all(4)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 18)
	panel.add_child(col)

	col.add_child(UI.label("OPTIONS", 40, UI.YELLOW))

	col.add_child(_slider("Master", Settings.master_volume, func(v): Settings.master_volume = v))
	col.add_child(_slider("Music", Settings.music_volume, func(v): Settings.music_volume = v))
	col.add_child(_slider("Sound FX", Settings.sfx_volume, func(v):
		Settings.sfx_volume = v
		Settings.click()))

	var fs := CheckButton.new()
	fs.text = "Fullscreen"
	fs.button_pressed = Settings.fullscreen
	fs.add_theme_font_override("font", UI.FONT)
	fs.add_theme_font_size_override("font_size", 20)
	fs.toggled.connect(func(on):
		Settings.fullscreen = on
		Settings.apply()
		Settings.save_settings()
		Settings.click())
	col.add_child(fs)

	var reset := UI.button("Reset progress", 18)
	reset.custom_minimum_size = Vector2(320, 44)
	reset.pressed.connect(func():
		if reset.text == "Reset progress":
			reset.text = "Sure? click again"
		else:
			SaveData.reset()
			reset.text = "Progress wiped"
			reset.disabled = true)
	col.add_child(reset)

	var back := UI.button("Back", 24)
	back.pressed.connect(close)
	col.add_child(back)

	UI.pop_in(col.get_children(), 0.04)
	back.grab_focus.call_deferred()

func _slider(title: String, value: float, on_change: Callable) -> Control:
	var row := VBoxContainer.new()
	var top := HBoxContainer.new()
	var name_label := UI.label(title, 18)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pct := UI.label("%d%%" % roundi(value * 100), 18, UI.YELLOW)
	top.add_child(name_label)
	top.add_child(pct)
	row.add_child(top)

	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = value
	s.custom_minimum_size = Vector2(360, 24)
	s.value_changed.connect(func(v):
		pct.text = "%d%%" % roundi(v * 100)
		on_change.call(v)
		Settings.apply())
	s.drag_ended.connect(func(_c): Settings.save_settings())
	row.add_child(s)
	return row

func close() -> void:
	Settings.save_settings()
	closed.emit()
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
