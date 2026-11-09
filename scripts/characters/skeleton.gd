extends CharacterBody2D

## Undead swordsman.
##   PATROL  walks back and forth, turns at walls and ledges
##   CHASE   spotted you: faces you and closes in (won't walk off ledges)
##   ATTACK  winds up (glint = your cue to back off), lunges and slashes
##   HURT    staggered after enough hits ("poise"), otherwise it tanks hits mid-swing
##   DEAD    death animation, fades out
## Every number below is tweakable per skeleton in the inspector.

const FX = preload("res://scripts/utils/fx.gd")

enum State { PATROL, CHASE, ATTACK, HURT, DEAD }

@export var max_health := 6
@export var patrol_speed := 22.0
@export var chase_speed := 58.0
@export var sight_range := 120.0
@export var sight_height := 40.0     ## how far above/below it can notice you
@export var attack_range := 30.0
@export var attack_damage := 1
@export var attack_cooldown := 0.9
@export var lunge_speed := 140.0
## Attack animation frames where the blade can hit (inclusive).
@export var active_frames := Vector2i(7, 9)
## Frame that flashes so the player can read the attack coming.
@export var glint_frame := 5
## Hits needed to interrupt it while it's attacking.
@export var poise := 2
@export var knockback := 120.0

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var floor_ray: RayCast2D = $FloorRay
@onready var attack_box: Area2D = $AttackHitbox
@onready var attack_shape: CollisionShape2D = $AttackHitbox/CollisionShape2D
@onready var health_bar: ProgressBar = $HealthBar
@onready var hurt_sound: AudioStreamPlayer2D = $HurtSound
@onready var swing_sound: AudioStreamPlayer2D = $SwingSound

var state := State.PATROL
var health := 0
var dir := 1.0
var cooldown := 0.0
var hits_since_stagger := 0
var hit_player := false
var sprite_x := 0.0
var player = null   # found by group "player"


func _ready() -> void:
	health = max_health
	health_bar.max_value = max_health
	health_bar.value = health
	sprite_x = sprite.position.x
	sprite.frame_changed.connect(_on_frame_changed)
	sprite.animation_finished.connect(_on_animation_finished)
	attack_box.body_entered.connect(_on_attack_box_body_entered)
	_face(dir)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	cooldown -= delta
	if player == null:
		player = get_tree().get_first_node_in_group("player")

	match state:
		State.PATROL: _patrol()
		State.CHASE: _chase()
		State.ATTACK, State.HURT, State.DEAD:
			velocity.x = move_toward(velocity.x, 0, 500 * delta)

	move_and_slide()


func _patrol() -> void:
	if is_on_floor() and (is_on_wall() or not floor_ray.is_colliding()):
		_face(-dir)
	velocity.x = dir * patrol_speed
	_play("walk")
	if _can_see_player():
		state = State.CHASE


func _chase() -> void:
	if not _player_alive() or _distance_to_player() > sight_range * 1.6:
		state = State.PATROL
		return
	var dx: float = player.global_position.x - global_position.x
	_face(signf(dx) if absf(dx) > 2 else dir)

	if absf(dx) <= attack_range and absf(player.global_position.y - global_position.y) < 24:
		velocity.x = 0
		if cooldown <= 0:
			_start_attack()
		else:
			_play("idle")
		return

	# stop at ledges instead of chasing you off a cliff
	if is_on_floor() and not floor_ray.is_colliding():
		velocity.x = 0
		_play("idle")
		return
	velocity.x = dir * chase_speed
	_play("walk")


func _start_attack() -> void:
	state = State.ATTACK
	hit_player = false
	velocity.x = 0
	sprite.play("attack")


func _on_frame_changed() -> void:
	if sprite.animation != "attack":
		return
	var f := sprite.frame
	if f == glint_frame:
		# telegraph: bright flash right before the swing
		sprite.modulate = Color(2.2, 2.2, 2.2)
		create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.15)
	if f == active_frames.x:
		velocity.x = dir * lunge_speed
		swing_sound.play()
		FX.shake(self, 1.0, 0.1)
	attack_shape.set_deferred("disabled", not (f >= active_frames.x and f <= active_frames.y))


func _on_animation_finished() -> void:
	match sprite.animation:
		&"attack":
			attack_shape.set_deferred("disabled", true)
			cooldown = attack_cooldown
			state = State.CHASE
		&"hurt":
			state = State.CHASE
		&"death":
			var t := create_tween()
			t.tween_interval(0.4)
			t.tween_property(self, "modulate:a", 0.0, 0.5)
			t.tween_callback(queue_free)


func _on_attack_box_body_entered(body: Node) -> void:
	if hit_player or state != State.ATTACK:
		return
	if body.has_method("take_damage"):
		hit_player = true
		body.take_damage(attack_damage, global_position)


func take_damage(amount: int, from := Vector2.INF) -> void:
	if state == State.DEAD:
		return
	health -= amount
	health_bar.show()
	create_tween().tween_property(health_bar, "value", health, 0.15)
	hurt_sound.pitch_scale = randf_range(0.6, 0.8)
	hurt_sound.play()

	var push := -dir
	if from != Vector2.INF:
		push = signf(global_position.x - from.x)
	_flash()

	if health <= 0:
		_die()
		return

	# it notices you when hit from behind
	if state == State.PATROL:
		state = State.CHASE

	hits_since_stagger += 1
	if state == State.ATTACK and hits_since_stagger < poise:
		return   # armored mid-swing: flinch but keep swinging
	hits_since_stagger = 0
	state = State.HURT
	attack_shape.set_deferred("disabled", true)
	velocity.x = push * knockback
	velocity.y = -60
	sprite.play("hurt")


func _die() -> void:
	state = State.DEAD
	attack_shape.set_deferred("disabled", true)
	$CollisionShape2D.set_deferred("disabled", true)
	collision_layer = 0
	health_bar.hide()
	velocity = Vector2.ZERO
	FX.shake(self, 3.0, 0.25)
	sprite.play("death")


func _flash() -> void:
	sprite.modulate = Color(3, 0.6, 0.6)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.2)


func _face(d: float) -> void:
	if d == 0:
		return
	dir = d
	sprite.flip_h = dir < 0
	sprite.position.x = sprite_x * dir
	attack_box.scale.x = dir
	floor_ray.position.x = absf(floor_ray.position.x) * dir


func _play(anim_name: StringName) -> void:
	if sprite.animation != anim_name:
		sprite.play(anim_name)


func _player_alive() -> bool:
	return is_instance_valid(player) and not player.dead


func _distance_to_player() -> float:
	return global_position.distance_to(player.global_position)


func _can_see_player() -> bool:
	if not _player_alive():
		return false
	var d: Vector2 = player.global_position - global_position
	if absf(d.x) > sight_range or absf(d.y) > sight_height:
		return false
	# only notices you in front of it, unless you're really close
	return signf(d.x) == dir or absf(d.x) < 30
