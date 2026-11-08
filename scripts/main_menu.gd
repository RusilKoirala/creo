extends Control

const UI = preload("res://scripts/ui_style.gd")
const OPTIONS = preload("res://scripts/options_menu.gd")

@onready var title: Label = $Label
@onready var box: VBoxContainer = $VBoxContainer
@onready var play_btn: Button = $VBoxContainer/Button

var time := 0.0
var title_y := 0.0


func _ready() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false

	# restyle the existing buttons so they match the rest of the UI
	for b in box.get_children():
		b.add_theme_font_override("font", UI.FONT)
		b.add_theme_stylebox_override("normal", UI.box(UI.YELLOW, 16))
		b.add_theme_stylebox_override("hover", UI.box(UI.ORANGE, 16))
		b.add_theme_stylebox_override("pressed", UI.box(UI.ORANGE.darkened(0.15), 16, 1))
		b.add_theme_stylebox_override("focus", UI.box(Color(0, 0, 0, 0), 16, 0))
		b.add_theme_color_override("font_hover_color", UI.DARK)
		b.add_theme_color_override("font_pressed_color", UI.DARK)
		b.add_theme_color_override("font_focus_color", UI.DARK)
		UI.add_juice(b)
	$VBoxContainer/Button.text = "Play"
	if SaveData.tutorial_done:
		$VBoxContainer/Button.text = "Continue"

	# title: shadow + gentle float + pop in
	title.add_theme_color_override("font_color", UI.YELLOW)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	title.add_theme_constant_override("shadow_offset_y", 6)
	title.add_theme_constant_override("shadow_offset_x", 0)
	title.add_theme_constant_override("outline_size", 12)
	title.add_theme_color_override("font_outline_color", UI.DARK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.offset_left = -300
	title.offset_right = 300
	title.add_theme_font_size_override("font_size", 96)
	title.offset_top -= 30
	title.resized.connect(func(): title.pivot_offset = title.size / 2)
	title_y = title.position.y
	title.scale = Vector2(0.2, 0.2)
	create_tween().tween_property(title, "scale", Vector2.ONE, 0.5) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	var hint := UI.label("Esc to pause in game", 14, Color(1, 1, 1, 0.7))
	hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint.offset_top = -40
	hint.offset_left = -200
	hint.offset_right = 200
	add_child(hint)

	box.modulate.a = 0.0
	await get_tree().process_frame
	box.modulate.a = 1.0
	UI.pop_in(box.get_children(), 0.08)
	play_btn.grab_focus()

func _process(delta: float) -> void:
	time += delta
	title.position.y = title_y + sin(time * 2.0) * 6.0
	title.rotation = sin(time * 1.3) * 0.03


func _on_play_button_pressed() -> void:
	if SaveData.tutorial_done:
		SceneChanger.change_scene("res://sences/level/level_menu.tscn")
	else:
		SceneChanger.change_scene("res://sences/level/training_level.tscn")


func _on_button_option_pressed() -> void:
	box.hide()
	var o = OPTIONS.new()
	add_child(o)
	o.closed.connect(func():
		box.show()
		$VBoxContainer/Button2.grab_focus())


func _on_button_exit_pressed() -> void:
	get_tree().quit()
