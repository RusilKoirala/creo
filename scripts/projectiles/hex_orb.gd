extends Area2D



@export var warn_time := 0.8
@export var fall_speed := 260.0
@export var damage := 1
@export var radius := 4.0
@export var color := Color(0.8, 0.35, 1.0)

var falling := false
var dead := false
var time := 0.0
var ground_y := 200.0  


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 | 2
	monitoring = false
	var shape := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = radius
	shape.shape = c
	add_child(shape)
	body_entered.connect(_on_body_entered)

	# find the floor below so the warning line stops there
	var q := PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2(0, 400), 1)
	var hit := get_world_2d().direct_space_state.intersect_ray(q)
	if hit:
		ground_y = hit.position.y - global_position.y

	scale = Vector2.ZERO
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(warn_time, false).timeout
	if is_instance_valid(self) and not dead:
		falling = true
		monitoring = true


func _physics_process(delta: float) -> void:
	time += delta
	queue_redraw()
	if falling and not dead:
		position.y += fall_speed * delta
		ground_y -= fall_speed * delta
		if ground_y < -40:
			_pop() 


func _draw() -> void:
	if not falling and not dead:

		var a := 0.25 + 0.25 * sin(time * 20.0)
		draw_line(Vector2.ZERO, Vector2(0, ground_y), Color(color, a), 1.0)
		draw_line(Vector2(-5, ground_y), Vector2(5, ground_y), Color(color, a + 0.3), 2.0)
	var pulse := 1.0 + sin(time * 12.0) * 0.15
	draw_circle(Vector2.ZERO, (radius + 3) * pulse, Color(color, 0.25))
	draw_circle(Vector2.ZERO, radius, color)
	draw_circle(Vector2.ZERO, radius * 0.45, Color(1, 0.9, 1))


func _on_body_entered(body: Node) -> void:
	if dead:
		return
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage, global_position)
	_pop()


func _pop() -> void:
	dead = true
	set_deferred("monitoring", false)
	var t := create_tween().set_parallel()
	t.tween_property(self, "scale", Vector2(2.5, 2.5), 0.15)
	t.tween_property(self, "modulate:a", 0.0, 0.15)
	t.chain().tween_callback(queue_free)
