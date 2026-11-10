extends Area2D


@export var speed := 130.0
@export var max_distance := 220.0
@export var damage := 1
@export var height := 12.0
@export var color := Color(0.75, 0.3, 1.0)

var dir := 1.0
var traveled := 0.0
var time := 0.0
var fading := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 | 2
	var shape := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(8, height - 2)
	shape.shape = r
	shape.position = Vector2(0, -height / 2 - 1.5)  
	add_child(shape)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	time += delta
	queue_redraw()
	if fading:
		return
	position.x += dir * speed * delta
	traveled += speed * delta
	if traveled >= max_distance:
		_fade()


func _draw() -> void:
	for i in 4:
		var x := (i - 1.5) * 3.0 * -dir
		var h := height * (0.6 + 0.4 * sin(time * 25.0 + i * 1.7)) * (1.0 - i * 0.15)
		var w := 3.5 - i * 0.4
		var pts := PackedVector2Array([Vector2(x - w, 0), Vector2(x + w, 0), Vector2(x + dir * 1.5, -h)])
		draw_colored_polygon(pts, color.lightened(i * 0.12))
	draw_line(Vector2(-6, -0.5), Vector2(6, -0.5), Color(1, 0.8, 1, 0.9), 1.0)


func _on_body_entered(body: Node) -> void:
	if fading:
		return
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage, global_position)
	else:
		_fade()  


func _fade() -> void:
	fading = true
	set_deferred("monitoring", false)
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.2)
	t.tween_callback(queue_free)
