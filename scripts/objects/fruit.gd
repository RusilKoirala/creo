extends Area2D

@export var heal_amount := 1

@onready var sprite = $Sprite2D
@onready var sound = $PickupSound

var time := 0.0
var taken := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	time = randf() * TAU  

func _process(delta: float) -> void:
	time += delta * 3.0
	sprite.position.y = sin(time) * 2.0

func _on_body_entered(body: Node2D) -> void:
	if taken or not body.has_method("heal"):
		return

	if body.health >= body.max_health:
		return
	taken = true
	set_deferred("monitoring", false)
	body.heal(heal_amount)
	sound.play()

	var t := create_tween().set_parallel()
	t.tween_property(sprite, "scale", Vector2(1.8, 1.8), 0.2)
	t.tween_property(self, "modulate:a", 0.0, 0.2)
	await sound.finished
	queue_free()
