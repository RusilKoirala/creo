extends CharacterBody2D

const FX = preload("res://scripts/utils/fx.gd")

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

# upgrade stuff (see Upgrades autoload)
const DOUBLE_JUMP_VELOCITY = -260.0
const AIR_DASH_VELOCITY = 280.0
const AIR_DASH_TIME = 0.18
const DASH_STRIKE_DAMAGE = 1

var invincible := false
var dead := false

var is_dashing := false
var air_dashing := false
var dash_timer := 0.0
var ghost_timer := 0.0
var air_jumps_left := 0
var can_air_dash := false
var dash_hitbox: Area2D
var dash_hits: Array = []

# weapon comes from the Inventory autoload, see _equip()
@onready var weapon_holder: Node2D = $WeaponHolder
var weapon: Weapon = null

var coyote_timer := 0.0
var jump_buffer_timer := 0.0
var was_on_floor := true
var fall_speed := 0.0


signal health_changed(current, max_value)

@export var max_health := 3   ## before Extra Heart upgrades
var base_health := 3
var health := 3



func _ready() -> void:
	Engine.time_scale = 1.0   # in case we died during slow-mo
	sprite.animation_finished.connect(_on_animation_finished)
	base_health = max_health
	max_health = base_health + Upgrades.level(&"heart")
	health = max_health
	_make_dash_hitbox()
	Upgrades.changed.connect(_on_upgrade_changed)
	health_changed.emit(health, max_health)
	Inventory.equipped_changed.connect(_equip)
	_equip(Inventory.current())
	_spawn_at_checkpoint()

func _physics_process(delta: float) -> void:
	if not is_on_floor() and not air_dashing:
		velocity += get_gravity() * delta

	if dead:
		velocity.x = move_toward(velocity.x, 0, 400 * delta)
		move_and_slide()
		return

	# coyote time + jump buffer timers
	if is_on_floor():
		coyote_timer = COYOTE_TIME
		air_jumps_left = 1 if Upgrades.has(&"double_jump") else 0
		can_air_dash = Upgrades.has(&"air_dash")
	else:
		coyote_timer -= delta

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER
	else:
		jump_buffer_timer -= delta

	_handle_weapon_input()

	if jump_buffer_timer > 0 and coyote_timer > 0 and not is_dashing:
		_jump(JUMP_VELOCITY, randf_range(0.95, 1.1))
	elif Input.is_action_just_pressed("jump") and coyote_timer <= 0 and air_jumps_left > 0 and not is_dashing:
		# double jump
		air_jumps_left -= 1
		_jump(DOUBLE_JUMP_VELOCITY, 1.35)
		_ghost(Color(1, 1, 1, 0.5))

	# short hop when jump is released early
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= JUMP_CUT

	# Start dash (ground roll, or air dash if unlocked)
	if Input.is_action_just_pressed("dash") and not is_dashing:
		if is_on_floor():
			_start_dash(false)
		elif can_air_dash:
			can_air_dash = false
			_start_dash(true)

	if is_dashing:
		_dash_process(delta)
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
	if sprite.animation == "roll" and not air_dashing:
		_end_dash()


func _jump(power: float, pitch: float) -> void:
	velocity.y = power
	jump_buffer_timer = 0
	coyote_timer = 0
	jump_sound.pitch_scale = pitch
	jump_sound.play()
	FX.squash(sprite, Vector2(0.8, 1.2))


func _start_dash(in_air: bool) -> void:
	is_dashing = true
	air_dashing = in_air
	# dash where you're holding, otherwise where you're facing
	var dir := signf(Input.get_axis("move_left", "move_right"))
	if dir == 0:
		dir = -1.0 if sprite.flip_h else 1.0
	sprite.flip_h = dir < 0
	if in_air:
		velocity = Vector2(dir * AIR_DASH_VELOCITY, 0)
		dash_timer = AIR_DASH_TIME
		FX.squash(sprite, Vector2(1.4, 0.7))
		jump_sound.pitch_scale = 1.6
		jump_sound.play()
	else:
		velocity.x = dir * DASH_VELOCITY
		FX.squash(sprite, Vector2(1.25, 0.8))
	sprite.play("roll")
	ghost_timer = 0.0
	dash_hits.clear()
	dash_hitbox.set_deferred("monitoring", Upgrades.has(&"dash_strike"))


func _dash_process(delta: float) -> void:
	ghost_timer -= delta
	if ghost_timer <= 0:
		ghost_timer = 0.035
		_ghost(Color(0.5, 0.8, 1.0, 0.55))
	if air_dashing:
		velocity.y = 0
		dash_timer -= delta
		if dash_timer <= 0 or is_on_wall():
			velocity.x *= 0.5   # keep a bit of momentum
			_end_dash()


func _end_dash() -> void:
	is_dashing = false
	air_dashing = false
	dash_hitbox.set_deferred("monitoring", false)
	if not dead:
		sprite.play("idle")


# fading copy of the current frame, for dash trails
func _ghost(color: Color) -> void:
	var g := Sprite2D.new()
	g.texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	g.flip_h = sprite.flip_h
	g.modulate = color
	get_parent().add_child(g)
	g.global_position = sprite.global_position
	var t := g.create_tween()
	t.tween_property(g, "modulate:a", 0.0, 0.25)
	t.tween_callback(g.queue_free)


# area that only listens while dashing with the Dash Strike upgrade
func _make_dash_hitbox() -> void:
	dash_hitbox = Area2D.new()
	dash_hitbox.collision_layer = 0
	dash_hitbox.collision_mask = 4   # enemies
	dash_hitbox.monitoring = false
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 9.0
	shape.shape = circle
	shape.position = Vector2(0, -6)
	dash_hitbox.add_child(shape)
	add_child(dash_hitbox)
	dash_hitbox.body_entered.connect(func(body: Node):
		if body in dash_hits or not body.has_method("take_damage"):
			return
		dash_hits.append(body)
		body.take_damage(DASH_STRIKE_DAMAGE, global_position)
		FX.hit_stop(self, 0.05))


func _handle_weapon_input() -> void:
	weapon_holder.scale.x = -1 if sprite.flip_h else 1
	if Input.is_action_just_pressed("attack") and weapon:
		weapon.attack()
	if Input.is_action_just_pressed("next_weapon"):
		Inventory.cycle()
	for i in 4:
		if Input.is_action_just_pressed("weapon_%d" % (i + 1)):
			Inventory.equip(i)

# swap the scene under WeaponHolder for the newly equipped item
func _equip(item: ItemData) -> void:
	if weapon:
		weapon.queue_free()
		weapon = null
	if item == null or item.equip_scene == null:
		return
	weapon = item.equip_scene.instantiate()
	weapon.player = self
	weapon.item = item
	weapon_holder.add_child(weapon)

func take_damage(amount: int, from := Vector2.INF) -> void:
	if invincible or dead:
		return
	if is_dashing and Upgrades.has(&"dash_strike"):
		return   # dash strike = i-frames
	if is_dashing:
		_end_dash()
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
	air_dashing = false
	sprite.play("hit")
	sprite.modulate = Color(1, 0.4, 0.4)
	velocity.y = -200
	FX.shake(self, 4.0, 0.4)
	Engine.time_scale = 0.4   # dramatic slow-mo
	await get_tree().create_timer(0.8, true, false, true).timeout
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()

# died after touching a checkpoint: start there instead
func _spawn_at_checkpoint() -> void:
	if not Checkpoint.has_for(get_tree().current_scene):
		return
	Checkpoint.on_respawn()
	global_position = Checkpoint.position
	var cam := get_node_or_null("Camera2D") as Camera2D
	if cam:
		cam.reset_smoothing.call_deferred()


# picked up an upgrade mid-level: works right away
func _on_upgrade_changed(id: StringName) -> void:
	match id:
		&"heart":
			max_health = base_health + Upgrades.level(&"heart")
			heal(1)
		&"double_jump":
			air_jumps_left = 1
		&"air_dash":
			can_air_dash = true


func heal(amount: int) -> void:
	health = min(health + amount, max_health)
	health_changed.emit(health, max_health)
	sprite.modulate = Color(0.6, 1.6, 0.6)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.3)
	FX.squash(sprite, Vector2(1.2, 1.2))
