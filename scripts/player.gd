extends CharacterBody2D

@onready var sprite = $AnimatedSprite2D
@onready var jump_sound = $JumpSound
@onready var hurt_sound = $HurtSound


const SPEED = 130.0
const JUMP_VELOCITY = -300.0
const DASH_VELOCITY = 250.0

var invincible := false

var is_dashing := false
const BOOMERANG = preload("res://sences/weapons/boomrang.tscn") 
var can_throw := true


signal health_changed(current, max_value)

@export var max_health := 3
var health := 3



func _ready() -> void:
	sprite.animation_finished.connect(_on_animation_finished)
	health = max_health
	health_changed.emit(health, max_health)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		
		
	if Input.is_action_just_pressed("throw") and can_throw:
		throw_boomerang()

	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_dashing:
		velocity.y = JUMP_VELOCITY
		jump_sound.play()

	# Start dash
	if Input.is_action_just_pressed("dash") and is_on_floor() and not is_dashing:
		is_dashing = true
		var facing := -1.0 if sprite.flip_h else 1.0
		velocity.x = facing * DASH_VELOCITY
		sprite.play("roll")

	if is_dashing:
		move_and_slide()
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

	move_and_slide()

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
	
func take_damage(amount: int) -> void:
	if invincible:
		return
	health -= amount
	hurt_sound.play()
	health_changed.emit(health, max_health)
	invincible = true
	velocity = Vector2(-200 if not sprite.flip_h else 200, -150)  
	sprite.modulate = Color(1, 1, 1, 0.5)
	if health <= 0:
		get_tree().reload_current_scene()  
		return
	await get_tree().create_timer(1.0).timeout
	invincible = false
	sprite.modulate = Color.WHITE

func heal(amount: int) -> void:
	health = min(health + amount, max_health)
	health_changed.emit(health, max_health)
