@tool
extends Area2D



@export var lit_color := Color(0.35, 0.95, 0.5)
@export var unlit_color := Color(0.55, 0.5, 0.6)

@onready var sound: AudioStreamPlayer2D = $Sound

var lit := false
var time := 0.0
var raise := 0.0  


func _ready() -> void:
	if Engine.is_editor_hint():
		raise = 1.0
		return
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)

	if Checkpoint.has_for(get_tree().current_scene) and Checkpoint.flag_id == _id():
		lit = true
		raise = 1.0


func _id() -> String:
	return str(get_tree().current_scene.get_path_to(self))


func _process(delta: float) -> void:
	time += delta
	queue_redraw()


func _on_body_entered(body: Node) -> void:
	if lit or not body.is_in_group("player"):
		return
	lit = true
	Checkpoint.activate(get_tree().current_scene, global_position + Vector2(0, -2), _id())

	for f in get_tree().get_nodes_in_group("checkpoint"):
		if f != self:
			f.lit = false
			f.raise = 0.0
	sound.play()
	create_tween().tween_property(self, "raise", 1.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if body.has_method("heal"):
		body.heal(1)  
	var hud = body.get_node_or_null("HUD")
	if hud and hud.has_method("show_toast"):
		hud.show_toast("Checkpoint!")


func _enter_tree() -> void:
	add_to_group("checkpoint")


func _draw() -> void:
	var pole_h := 28.0

	draw_rect(Rect2(-4, -3, 8, 3), Color(0.3, 0.28, 0.35))

	draw_line(Vector2(0, -3), Vector2(0, -pole_h), Color(0.75, 0.72, 0.8), 2.0)
	draw_circle(Vector2(0, -pole_h), 1.6, Color(1, 0.86, 0.2) if lit else Color(0.6, 0.6, 0.65))
	
	var top := lerpf(-8.0, -pole_h + 2, raise)
	var c := lit_color if lit else unlit_color
	var wave := sin(time * 6.0) * 1.5
	var pts := PackedVector2Array([
		Vector2(1, top), Vector2(12, top + 3 + wave), Vector2(1, top + 7)])
	draw_colored_polygon(pts, c)
	draw_polyline(pts + PackedVector2Array([pts[0]]), c.darkened(0.4), 1.0)
	if lit:
		draw_circle(Vector2(0, -pole_h), 4.0 + sin(time * 5.0), Color(1, 0.9, 0.4, 0.25))
