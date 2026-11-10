extends CharacterBody2D

## Purple slime that keeps its distance and lobs goo at you.
##   - sees you (in range + nothing in the way) -> swells up (telegraph) -> spits
##   - you get too close -> hops away (unless there's a ledge behind it)
##   - touching it hurts, like the goblin
## Place it on high ground / behind gaps so the player has to work to reach it.

const FX = preload("res://scripts/utils/fx.gd")
const GOO = preload("res://scenes/projectiles/goo.tscn")

@export var health := 2
@export var damage := 1
@export var sight_range := 140.0
@export var flee_range := 40.0       ## player closer than this = hop away
@export var fire_cooldown := 1.8
@export var windup := 0.4            ## swell-up time before spitting
@export var flight_time := 0.75      ## how long goo takes to reach you (lower = flatter, faster shot)
@export var hop_velocity := Vector2(70, -170)
@export var hop_cooldown := 1.2

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var back_ray: RayCast2D = $BackRay
@onready var spit_sound: AudioStreamPlayer2D = $SpitSound

var dir := -1.0
var cooldown := 0.6
var hop_timer := 0.0
var winding := false
var dying := false
var knockback := 0.0
var player = null


func _ready() -> void:
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	cooldown = randf_range(0.4, 1.0)   # so a group doesn't fire in sync


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	cooldown -= delta
	hop_timer -= delta
	if player == null:
		player = get_tree().get_first_node_in_group("player")

	knockback = move_toward(knockback, 0, 600 * delta)
	if absf(knockback) > 1:
		velocity.x = knockback
	elif is_on_floor():
		velocity.x = move_toward(velocity.x, 0, 400 * delta)

	if _player_alive():
		var d: Vector2 = player.global_position - global_position
		if absf(d.x) < sight_range and absf(d.y) < sight_range * 0.75:
			if not winding:
				_face(signf(d.x))
			if absf(d.x) < flee_range and is_on_floor() and hop_timer <= 0 and not winding:
				_hop_away()
			elif cooldown <= 0 and not winding and is_on_floor() and _can_see(player.global_position):
				_spit()

	move_and_slide()


func _hop_away() -> void:
	hop_timer = hop_cooldown
	# don't jump off a cliff to get away
	if not back_ray.is_colliding():
		return
	velocity = Vector2(-dir * hop_velocity.x, hop_velocity.y)
	FX.squash(sprite, Vector2(0.7, 1.3))


func _spit() -> void:
	winding = true
	sprite.play("damage")   # the purple "puffed" frames read nicely as a windup
	# swell + flash = "it's about to shoot"
	var t := create_tween()
	t.tween_property(sprite, "scale", Vector2(1.35, 1.35), windup).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(sprite, "modulate", Color(1.8, 1.4, 2.2), windup)
	await t.finished
	if dying:
		return
	sprite.scale = Vector2.ONE
	sprite.modulate = Color.WHITE
	sprite.play("active")
	FX.squash(sprite, Vector2(1.4, 0.65))
	winding = false
	cooldown = fire_cooldown
	if not _player_alive():
		return

	var goo := GOO.instantiate()
	var start := global_position + Vector2(dir * 6, -10)
	var target: Vector2 = player.global_position + Vector2(0, -6)
	# solve the arc so it lands where the player is standing right now
	var g: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)
	var tt := flight_time
	goo.velocity = Vector2((target.x - start.x) / tt, (target.y - start.y - 0.5 * g * tt * tt) / tt)
	get_parent().add_child(goo)
	goo.global_position = start
	spit_sound.pitch_scale = randf_range(1.3, 1.6)
	spit_sound.play()


func _can_see(target: Vector2) -> bool:
	var q := PhysicsRayQueryParameters2D.create(global_position + Vector2(0, -8), target + Vector2(0, -8), 1)
	return get_world_2d().direct_space_state.intersect_ray(q).is_empty()


func _face(d: float) -> void:
	if d == 0:
		return
	dir = d
	sprite.flip_h = dir < 0
	back_ray.position.x = -absf(back_ray.position.x) * dir


func _player_alive() -> bool:
	return is_instance_valid(player) and not player.dead


func take_damage(amount: int, from := Vector2.INF) -> void:
	if dying:
		return
	health -= amount
	var push := -dir
	if from != Vector2.INF:
		push = signf(global_position.x - from.x)
	knockback = push * 150
	velocity.y = -80
	cooldown = maxf(cooldown, 0.5)   # getting hit delays its next shot
	FX.hit_stop(self, 0.05)
	FX.shake(self, 1.5, 0.15)
	FX.squash(sprite, Vector2(1.3, 0.7))
	if health <= 0:
		_die()
		return
	sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	if not dying and not winding:
		sprite.modulate = Color.WHITE


func _die() -> void:
	dying = true
	set_physics_process(false)
	hitbox.set_deferred("monitoring", false)
	$CollisionShape2D.set_deferred("disabled", true)
	sprite.play("damage")
	sprite.modulate = Color.RED
	FX.shake(self, 2.5, 0.2)
	var t := create_tween().set_parallel()
	t.tween_property(self, "position:y", position.y - 16, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(sprite, "rotation", 6.0 * (1 if randf() > 0.5 else -1), 0.4)
	t.tween_property(sprite, "scale", Vector2.ZERO, 0.4).set_delay(0.1)
	t.tween_property(sprite, "modulate:a", 0.0, 0.4).set_delay(0.1)
	await t.finished
	queue_free()


func _on_hitbox_body_entered(body: Node) -> void:
	if not dying and body.has_method("take_damage"):
		body.take_damage(damage, global_position)
