extends Area2D



@export var damage := 1
@export var radius := 3.0
@export var color := Color(0.7, 0.35, 0.95)
@export var gravity_scale := 1.0
@export var lifetime := 4.0

var velocity := Vector2.ZERO
var dead := false
var g := 980.0


func _ready() -> void:
	g = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)
	collision_layer = 0
	collision_mask = 1 | 2 
	var shape := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = radius
	shape.shape = c
	add_child(shape)
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(lifetime, false).timeout.connect(_splat)


func _physics_process(delta: float) -> void:
	if dead:
		return
	velocity.y += g * gravity_scale * delta
	position += velocity * delta
	rotation = velocity.angle()


func _draw() -> void:
	
	draw_set_transform(Vector2.ZERO, 0, Vector2(1.4, 0.85))
	draw_circle(Vector2.ZERO, radius + 1, color.darkened(0.5))
	draw_circle(Vector2.ZERO, radius, color)
	draw_circle(Vector2(1, -1), radius * 0.35, Color(1, 1, 1, 0.7))


func _on_body_entered(body: Node) -> void:
	if dead:
		return
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage, global_position)
	_splat()


func _splat() -> void:
	if dead:
		return
	dead = true
	set_deferred("monitoring", false)
	rotation = 0
	var t := create_tween().set_parallel()
	t.tween_property(self, "scale", Vector2(2.2, 0.5), 0.12)
	t.tween_property(self, "modulate:a", 0.0, 0.25)
	t.chain().tween_callback(queue_free)
