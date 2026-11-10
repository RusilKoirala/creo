extends CanvasLayer

# Autoload "PauseMenu": press Esc in any level to freeze the game.

const UI = preload("res://scripts/ui/ui_style.gd")
const OPTIONS = preload("res://scenes/ui/options_menu.tscn")

var root: Control
var buttons: VBoxContainer
var options: Control

func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	root.hide()

func _build() -> void:
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.03, 0.1, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	buttons = VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 14)
	center.add_child(buttons)

	buttons.add_child(UI.label("PAUSED", 56, UI.YELLOW))
	_add("Resume", resume)
	_add("Restart", restart)
	_add("Options", open_options)
	_add("Level select", func(): _leave("res://scenes/ui/level_menu.tscn"))
	_add("Main menu", func(): _leave("res://scenes/ui/main_menu.tscn"))

func _add(text: String, cb: Callable) -> void:
	var b := UI.button(text, 26)
	b.pressed.connect(cb)
	buttons.add_child(b)

# only pause inside actual levels (scenes that have a Player)
func _in_level() -> bool:
	var scene := get_tree().current_scene
	return scene != null and scene.has_node("Player")

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if options:
		return   # options menu handles its own Esc
	if get_tree().paused:
		resume()
		get_viewport().set_input_as_handled()
	elif _in_level():
		pause()
		get_viewport().set_input_as_handled()

func pause() -> void:
	get_tree().paused = true
	root.show()
	UI.pop_in(buttons.get_children(), 0.05)
	buttons.get_child(1).grab_focus()

func resume() -> void:
	get_tree().paused = false
	root.hide()

func restart() -> void:
	resume()
	Engine.time_scale = 1.0
	Checkpoint.clear()   # Restart = from the very beginning
	get_tree().reload_current_scene()

func open_options() -> void:
	buttons.hide()
	options = OPTIONS.instantiate()
	root.add_child(options)
	options.closed.connect(func():
		options = null
		buttons.show()
		buttons.get_child(3).grab_focus())

func _leave(path: String) -> void:
	resume()
	Engine.time_scale = 1.0
	SceneChanger.change_scene(path)
