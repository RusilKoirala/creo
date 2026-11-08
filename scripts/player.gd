extends CharacterBody2D

const FX = preload("res://scripts/fx.gd")

@onready var sprite = $AnimatedSprite2D
@onready var jump_sound = $JumpSound
@onready var hurt_sound = $HurtSound


const SPEED = 130.0
const JUMP_VELOCITY = -300.0
const DASH_VELOCITY = 250.0

# feel stuff
const COYOTE_TIME = 0.1      # can still jump a moment after walking off a ledge
const JUMP_BUFFER = 0.12     # pressing jump right before landing still counts
const JUMP_CUT = 0.45        # let go of jump early = short hop

var invincible := false
var dead := false

var is_dashing := false
const BOOMERANG = preload("res://sences/weapons/boomrang.tscn")
var can_throw := true

var coyote_timer := 0.0
var jump_buffer_timer := 0.0
var was_on_floor := true
var fall_speed := 0.0


signal health_changed(current, max_value)

@export var max_health := 3
var health := 3



func _ready() -> void:
	Engine.time_scale = 1.0   # in case we died during slow-mo
	sprite.animation_finished.connect(_on_animation_finished)
	health = max_health
	health_changed.emit(health, max_health)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if dead:
		velocity.x = move_toward(velocity.x, 0, 400 * delta)
		move_and_slide()
		return

	# coyote time + jump buffer timers
	if is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer -= delta

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER
	else:
		jump_buffer_timer -= delta

	if Input.is_action_just_pressed("throw") and can_throw:
		throw_boomerang()

	if jump_buffer_timer > 0 and coyote_timer > 0 and not is_dashing:
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0
		coyote_timer = 0
		jump_sound.pitch_scale = randf_range(0.95, 1.1)
		jump_sound.play()
		FX.squash(sprite, Vector2(0.8, 1.2))

	# short hop when jump is released early
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= JUMP_CUT

	# Start dash
	if Input.is_action_just_pressed("dash") and is_on_floor() and not is_dashing:
		is_dashing = true
		var facing := -1.0 if sprite.flip_h else 1.0
		velocity.x = facing * DASH_VELOCITY
		sprite.play("roll")
		FX.squash(sprite, Vector2(1.25, 0.8))

	if is_dashing:
		_move()
		return   # skip normal movement/animations until roll ends

	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
		sprite.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	if not is_on_floor():
		pass
	elif direction:
		sprite.play("walking")
	else:
		sprite.play("idle")

	_move()

# move + detect landing so we can squish on impact
func _move() -> void:
	fall_speed = velocity.y
	move_and_slide()
	if is_on_floor() and not was_on_floor and fall_speed > 100:
		var squish: float = clamp(fall_speed / 600.0, 0.1, 0.3)
		FX.squash(sprite, Vector2(1.0 + squish, 1.0 - squish))
	was_on_floor = is_on_floor()

func _on_animation_finished() -> void:
	if sprite.animation == "roll":
		is_dashing = false


func throw_boomerang() -> void:
	can_throw = false
	var b = BOOMERANG.instantiate()
	b.direction = Vector2.LEFT if sprite.flip_h else Vector2.RIGHT
	b.player = self
	b.tree_exited.connect(func(): can_throw = true)
	get_parent().add_child(b)
	b.global_position = global_position + Vector2(b.direction.x * 12, -10)
	FX.squash(sprite, Vector2(1.1, 0.9), 0.1)

func take_damage(amount: int, from := Vector2.INF) -> void:
	if invincible or dead:
		return
	health -= amount
	hurt_sound.play()
	health_changed.emit(health, max_health)
	invincible = true

	# knock away from whatever hit us
	var push := -1.0 if sprite.flip_h else 1.0
	if from != Vector2.INF:
		push = sign(global_position.x - from.x)
		if push == 0:
			push = 1.0
	velocity = Vector2(push * 200, -150)

	FX.hit_stop(self, 0.08)
	FX.shake(self, 3.0, 0.25)

	if health <= 0:
		die()
		return

	# blink while invincible
	var blink := create_tween().set_loops(5)
	blink.tween_property(sprite, "modulate:a", 0.2, 0.1)
	blink.tween_property(sprite, "modulate:a", 1.0, 0.1)
	await get_tree().create_timer(1.0).timeout
	invincible = false
	sprite.modulate = Color.WHITE

func die() -> void:
	if dead:
		return
	dead = true
	invincible = true
	is_dashing = false
	sprite.play("hit")
	sprite.modulate = Color(1, 0.4, 0.4)
	velocity.y = -200
	FX.shake(self, 4.0, 0.4)
	Engine.time_scale = 0.4   # dramatic slow-mo
	await get_tree().create_timer(0.8, true, false, true).timeout
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()

func heal(amount: int) -> void:
	health = min(health + amount, max_health)
	health_changed.emit(health, max_health)
	sprite.modulate = Color(0.6, 1.6, 0.6)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.3)
	FX.squash(sprite, Vector2(1.2, 1.2))
