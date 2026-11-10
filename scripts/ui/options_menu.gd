extends Control


signal closed

const UI = preload("res://scripts/ui/ui_style.gd")

@onready var panel: PanelContainer = %Panel
@onready var fullscreen: CheckButton = %Fullscreen
@onready var reset_btn: Button = %Reset
@onready var back_btn: Button = %Back


func _ready() -> void:
	_bind(%MasterSlider, %MasterValue, Settings.master_volume,
		func(v): Settings.master_volume = v)
	_bind(%MusicSlider, %MusicValue, Settings.music_volume,
		func(v): Settings.music_volume = v)
	_bind(%SfxSlider, %SfxValue, Settings.sfx_volume, func(v):
		Settings.sfx_volume = v
		Settings.click())

	fullscreen.button_pressed = Settings.fullscreen
	fullscreen.toggled.connect(_on_fullscreen_toggled)
	reset_btn.pressed.connect(_on_reset_pressed)
	back_btn.pressed.connect(close)
	UI.add_juice(reset_btn)
	UI.add_juice(back_btn)

	_pop_in()
	back_btn.grab_focus.call_deferred()


# Hook a slider + its "%" label to a setting.
func _bind(slider: HSlider, pct: Label, value: float, on_change: Callable) -> void:
	slider.value = value
	pct.text = "%d%%" % roundi(value * 100)
	slider.value_changed.connect(func(v):
		pct.text = "%d%%" % roundi(v * 100)
		on_change.call(v)
		Settings.apply())
	slider.drag_ended.connect(func(_c): Settings.save_settings())


func _on_fullscreen_toggled(on: bool) -> void:
	Settings.fullscreen = on
	Settings.apply()
	Settings.save_settings()
	Settings.click()


func _on_reset_pressed() -> void:
	if reset_btn.text == "Reset progress":
		reset_btn.text = "Sure? click again"
	else:
		SaveData.reset()
		reset_btn.text = "Progress wiped"
		reset_btn.disabled = true


func _pop_in() -> void:
	panel.resized.connect(func(): panel.pivot_offset = panel.size / 2)
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.85, 0.85)
	var t := create_tween().set_parallel()
	t.tween_property(panel, "modulate:a", 1.0, 0.15)
	t.tween_property(panel, "scale", Vector2.ONE, 0.3) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func close() -> void:
	Settings.save_settings()
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
