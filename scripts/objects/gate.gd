@tool
extends StaticBody2D



@export var height := 48.0:
	set(v):
		height = v
		_rebuild()
@export var width := 8.0:
	set(v):
		width = v
		_rebuild()
@export var start_open := true
@export var bar_color := Color(0.32, 0.3, 0.38)

@onready var shape: CollisionShape2D = $CollisionShape2D

var closed_amount := 1.0  
var tween: Tween


func _ready() -> void:
	_rebuild()
	if Engine.is_editor_hint():
		closed_amount = 1.0
		return
	closed_amount = 0.0 if start_open else 1.0
	_apply()


func _rebuild() -> void:
	if not is_node_ready():
		return
	var r := RectangleShape2D.new()
	r.size = Vector2(width, height)
	shape.shape = r
	shape.position = Vector2(0, -height / 2)
	queue_redraw()


func close() -> void:
	_animate(1.0, 0.25, Tween.TRANS_BOUNCE)


func open() -> void:
	_animate(0.0, 0.8, Tween.TRANS_QUAD)


func _animate(target: float, time: float, trans: int) -> void:
	if tween:
		tween.kill()
	if target > 0.5:
		shape.set_deferred("disabled", false)
	tween = create_tween()
	tween.tween_method(func(v: float):
		closed_amount = v
		queue_redraw(), closed_amount, target, time).set_trans(trans).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_apply)


func _apply() -> void:
	shape.set_deferred("disabled", closed_amount < 0.5)
	queue_redraw()


func _draw() -> void:

	var h := height * closed_amount
	if h <= 0.5:
		return
	var top := -height
	draw_rect(Rect2(-width / 2 - 1, top - 3, width + 2, 3), bar_color.darkened(0.3))
	var bars := maxi(2, int(width / 3))
	for i in bars:
		var x := -width / 2 + (i + 0.5) * width / bars
		draw_line(Vector2(x, top), Vector2(x, top + h), bar_color, 2.0)
		
		draw_colored_polygon(PackedVector2Array([
			Vector2(x - 1.5, top + h - 2), Vector2(x + 1.5, top + h - 2), Vector2(x, top + h + 1)]),
			bar_color.lightened(0.25))
	draw_line(Vector2(-width / 2, top + h * 0.35), Vector2(width / 2, top + h * 0.35), bar_color.darkened(0.2), 1.5)
