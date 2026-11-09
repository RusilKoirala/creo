extends Area2D

@export var speed := 300.0
@export var max_distance := 50.0
@export var spin_speed := 20.0
@export var damage := 1

var direction := Vector2.RIGHT
var player: Node2D
var traveled := 0.0
var returning := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	rotation += spin_speed * delta   # spin

	if not returning:
		# fly outward
		global_position += direction * speed * delta
		traveled += speed * delta
		if traveled >= max_distance:
			returning = true
	else:
		# fly back to player
		if not is_instance_valid(player):
			queue_free()
			return
		var to_player := player.global_position - global_position
		global_position += to_player.normalized() * speed * delta
		if to_player.length() < 10:
			queue_free()  

func _on_body_entered(body: Node) -> void:
	if body == player:
		return
	if body.has_method("take_damage"):
		body.take_damage(damage, global_position)
	returning = true   # hit something, come back
