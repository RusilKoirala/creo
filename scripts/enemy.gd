extends CharacterBody2D

const FX = preload("res://scripts/fx.gd")

@export var speed := 40.0
@export var health := 3
@export var damage := 1

var direction := 1
var knockback := 0.0
var dying := false

@onready var sprite = $AnimatedSprite2D
@onready var floor_ray = $FloorRay
@onready var hitbox = $Hitbox

func _ready() -> void:
	hitbox.body_entered.connect(_on_hitbox_body_entered)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Turn around at walls or ledges
	if is_on_floor() and (is_on_wall() or not floor_ray.is_colliding()):
		direction *= -1

	knockback = move_toward(knockback, 0, 600 * delta)
	velocity.x = direction * speed + knockback
	sprite.flip_h = direction < 0
	floor_ray.position.x = abs(floor_ray.position.x) * direction

	move_and_slide()

func take_damage(amount: int, from := Vector2.INF) -> void:
	if dying:
		return
	health -= amount

	# get pushed back + little hop
	var push := float(-direction)
	if from != Vector2.INF:
		push = sign(global_position.x - from.x)
	knockback = push * 150
	velocity.y = -80

	FX.hit_stop(self, 0.05)
	FX.shake(self, 1.5, 0.15)
	FX.squash(sprite, Vector2(1.3, 0.7))

	if health <= 0:
		die()
		return

	sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	if not dying:
		sprite.modulate = Color.WHITE

func die() -> void:
	dying = true
	set_physics_process(false)
	hitbox.set_deferred("monitoring", false)
	$CollisionShape2D.set_deferred("disabled", true)
	sprite.play("damage")
	sprite.modulate = Color.RED

	FX.shake(self, 2.5, 0.2)

	# pop up, spin, shrink, fade, then gone
	var t := create_tween().set_parallel()
	t.tween_property(self, "position:y", position.y - 16, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(sprite, "rotation", 6.0 * (1 if randf() > 0.5 else -1), 0.4)
	t.tween_property(sprite, "scale", Vector2.ZERO, 0.4).set_delay(0.1)
	t.tween_property(sprite, "modulate:a", 0.0, 0.4).set_delay(0.1)
	await t.finished
	queue_free()

func _on_hitbox_body_entered(body: Node) -> void:
	if dying:
		return
	if body.has_method("take_damage"):
		body.take_damage(damage, global_position)
