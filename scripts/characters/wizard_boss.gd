class_name WizardBoss
extends CharacterBody2D


signal health_changed(current: int, max_value: int)
signal phase_changed(phase: int)
signal defeated

const FX = preload("res://scripts/utils/fx.gd")


const SHOCKWAVE = preload("res://scenes/projectiles/shockwave.tscn")
const HEX_ORB = preload("res://scenes/projectiles/hex_orb.tscn")
const SPRITE_X := -5.0  

@export var boss_name := "The Evil Wizard"
@export var max_health := 40

@export_group("Movement")
@export var run_speed := 70.0
@export var attack_range := 34.0
@export var chase_time := 1.6      

@export_group("Attacks")
@export var slash_damage := 1
@export var lunge_speed := 160.0
@export var leap_velocity := 280.0   
@export var leap_max_distance := 200.0
@export var slam_radius := 26.0      
@export var dazed_time := 1.4
@export var dazed_damage_multiplier := 2
@export var orb_count := 3
@export var orb_spread := 34.0
@export var orb_height := 80.0
@export var rest_time := 0.9         
@export_group("Phase 2")
@export_range(0.0, 1.0) var phase_two_at := 0.5
@export var phase_two_speed := 1.3   
@export var phase_two_orbs := 5
@export var phase_two_rest := 0.45

@export_group("Minions")

@export var minion_scene: PackedScene
@export var max_minions := 2
@export var summon_every := 4       

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var attack_box: Area2D = $AttackHitbox
@onready var attack_shape: CollisionShape2D = $AttackHitbox/CollisionShape2D
@onready var floor_ray: RayCast2D = $FloorRay
@onready var hurt_sound: AudioStreamPlayer2D = $HurtSound
@onready var swing_sound: AudioStreamPlayer2D = $SwingSound
@onready var boom_sound: AudioStreamPlayer2D = $BoomSound
@onready var cast_sound: AudioStreamPlayer2D = $CastSound

var health := 0
var phase := 1
var active := false
var dead := false
var invulnerable := false
var dazed := false
var leaping := false
var dir := -1.0
var move_dir := 0.0
var speed_mult := 1.0
var hit_player := false
var moves_done := 0
var last_move := &""
var minions: Array = []
var player = null


func _ready() -> void:
	add_to_group("boss")
	health = max_health
	sprite.frame_changed.connect(_on_frame_changed)
	attack_box.body_entered.connect(_on_attack_box_body_entered)
	_face(dir)
	sprite.play("idle")


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	if leaping:
		pass
	elif move_dir != 0:
		velocity.x = move_dir * run_speed * speed_mult
	else:
		velocity.x = move_toward(velocity.x, 0, 700 * delta)
	move_and_slide()


func start_fight() -> void:
	if active or dead:
		return
	active = true
	player = get_tree().get_first_node_in_group("player")
	_face_player()
	_flash(Color(2, 1.4, 2.4))
	FX.shake(self, 3.0, 0.5)
	boom_sound.play()
	await _wait(0.8)
	_brain()


func _brain() -> void:
	while not dead:
		if not _player_alive():
			await _wait(0.5)
			continue
		if phase == 1 and health <= max_health * phase_two_at:
			await _enter_phase_two()
			if dead:
				return
		await _next_move()
		if dead:
			return
		await _rest()


func _next_move() -> void:
	var dist := absf(player.global_position.x - global_position.x)
	moves_done += 1

	if phase == 2 and minion_scene and moves_done % summon_every == 0 and _alive_minions() < max_minions:
		await _summon()
		return

	var options: Array
	if dist <= attack_range * 1.3:
		
		options = [&"slash", &"slash", &"smash"]
	elif dist < 110:
		options = [&"chase", &"chase", &"leap", &"hex"]
		
		
		
	else:
		options = [&"leap", &"hex", &"hex", &"chase"]
	
	if options.size() > 1 and last_move in options and randf() < 0.7:
		options = options.filter(func(o): return o != last_move)
		
	var move: StringName = options.pick_random()
	
	
	last_move = move

	match move:
		&"slash": await _slash()
		&"smash": await _smash()
		&"leap": await _leap()
		&"hex": await _hex()
		&"chase":
			await _approach()
			if dead:
				return
			if _in_range():
				await _slash()
				if phase == 2 and not dead:
					await _smash()   
			else:
				await _hex()


func _rest() -> void:
	move_dir = 0
	_face_player()
	_play("idle")
	await _wait(phase_two_rest if phase == 2 else rest_time)


func _approach() -> void:
	var t := 0.0
	while t < chase_time and not dead and _player_alive():
		var dx: float = player.global_position.x - global_position.x
		if absf(dx) <= attack_range:
			break
		_face(signf(dx))
		if is_on_floor() and not floor_ray.is_colliding():
			break  
		move_dir = dir
		_play("run")
		await get_tree().physics_frame
		if not get_tree().paused:
			t += get_physics_process_delta_time()
	move_dir = 0


func _slash() -> void:
	_face_player()
	hit_player = false
	sprite.play("attack1")
	await sprite.animation_finished


func _smash() -> void:
	_face_player()
	hit_player = false
	sprite.play("attack2")
	await sprite.animation_finished


func _leap() -> void:
	_face_player()
	_play("idle")
	FX.squash(sprite, Vector2(1.25, 0.75), 0.4 / speed_mult)
	_flash(Color(1.8, 1.0, 2.4))
	await _wait(0.45 / speed_mult)
	if dead or not _player_alive():
		return

	var g: float = get_gravity().y
	var air_time := 2.0 * leap_velocity / g
	var dx: float = clampf(player.global_position.x - global_position.x, -leap_max_distance, leap_max_distance)
	velocity = Vector2(dx / air_time, -leap_velocity)
	leaping = true
	sprite.play("jump")
	await _wait(0.1)
	while not is_on_floor() and not dead:
		if velocity.y > 0:
			_play("fall")
		await get_tree().physics_frame
	leaping = false
	velocity.x = 0
	if dead:
		return

	boom_sound.play()
	FX.shake(self, 4.0, 0.35)
	FX.squash(sprite, Vector2(1.3, 0.7))
	_spawn_wave(1)
	_spawn_wave(-1)
	if _player_alive():
		var d: Vector2 = player.global_position - global_position
		if absf(d.x) < slam_radius and absf(d.y) < 20:
			player.take_damage(1, global_position)

	dazed = true
	_play("idle")
	sprite.speed_scale = 0.4
	var blink := create_tween().set_loops(int(dazed_time / 0.2))
	blink.tween_property(sprite, "modulate", Color(0.6, 0.6, 0.7), 0.1)
	blink.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	await _wait(dazed_time)
	blink.kill()
	sprite.modulate = Color.WHITE
	sprite.speed_scale = speed_mult
	dazed = false


func _hex() -> void:
	_face_player()
	_play("idle")
	cast_sound.play()
	var glow := create_tween()
	glow.tween_property(sprite, "modulate", Color(1.8, 0.9, 2.6), 0.35 / speed_mult)
	await glow.finished
	if dead or not _player_alive():
		sprite.modulate = Color.WHITE
		return
	var n := phase_two_orbs if phase == 2 else orb_count
	var center: float = player.global_position.x
	var y: float = player.global_position.y - orb_height
	for i in n:
		var orb := HEX_ORB.instantiate()
		orb.add_to_group("boss_projectile")
		get_parent().add_child(orb)
		orb.global_position = Vector2(center + (i - (n - 1) / 2.0) * orb_spread + randf_range(-5, 5), y)
		if phase == 2:
			await _wait(0.1)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.3)
	await _wait(0.6)


func _summon() -> void:
	_play("idle")
	cast_sound.play()
	_flash(Color(1.5, 0.8, 2.5))
	FX.shake(self, 2.0, 0.3)
	await _wait(0.4)
	for side in [-1, 1]:
		if _alive_minions() >= max_minions:
			break
		var m: Node2D = minion_scene.instantiate()
		get_parent().add_child(m)
		m.global_position = global_position + Vector2(side * 40, -16)
		m.scale = Vector2.ZERO
		m.create_tween().tween_property(m, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		minions.append(m)
	await _wait(0.5)


func _enter_phase_two() -> void:
	phase = 2
	invulnerable = true
	move_dir = 0
	_play("idle")
	phase_changed.emit(2)
	boom_sound.play()
	FX.shake(self, 4.0, 0.8)
	if _player_alive():
		var d: Vector2 = player.global_position - global_position
		if d.length() < 70:
			player.velocity = Vector2(signf(d.x if d.x != 0 else 1.0) * 220, -160)
	var t := create_tween().set_loops(4)
	t.tween_property(sprite, "modulate", Color(2.2, 1.0, 2.8), 0.1)
	t.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	await _wait(1.0)
	speed_mult = phase_two_speed
	sprite.speed_scale = speed_mult
	sprite.self_modulate = Color(1.15, 0.85, 1.3)  
	invulnerable = false


func _on_frame_changed() -> void:
	var f := sprite.frame
	match sprite.animation:
		&"attack1":
			if f == 2:
				_flash(Color(2.4, 2.4, 2.4))
			if f == 3:
				velocity.x = dir * lunge_speed
				swing_sound.play()
			_set_hitbox(f >= 3 and f <= 6)
		&"attack2":
			if f == 3:
				_flash(Color(2.4, 2.4, 2.4))
			if f == 5:
				boom_sound.play()
				FX.shake(self, 3.0, 0.25)
				_spawn_wave(dir)
				if phase == 2:
					_spawn_wave(-dir)
			_set_hitbox(f >= 4 and f <= 6)
		_:
			_set_hitbox(false)


func _set_hitbox(on: bool) -> void:
	attack_shape.set_deferred("disabled", not on)


func _on_attack_box_body_entered(body: Node) -> void:
	if hit_player or dead:
		return
	if body.is_in_group("player") and body.has_method("take_damage"):
		hit_player = true
		body.take_damage(slash_damage, global_position)


func _spawn_wave(d: float) -> void:
	var w := SHOCKWAVE.instantiate()
	w.dir = d
	w.add_to_group("boss_projectile")
	if phase == 2:
		w.speed *= 1.25
	get_parent().add_child(w)
	w.global_position = global_position + Vector2(d * 16, 0)


func take_damage(amount: int, _from := Vector2.INF) -> void:
	if not active or dead or invulnerable:
		return
	var dmg := amount * (dazed_damage_multiplier if dazed else 1)
	health -= dmg
	health_changed.emit(maxi(health, 0), max_health)
	hurt_sound.pitch_scale = randf_range(0.5, 0.65)
	hurt_sound.play()
	_flash(Color(3, 0.7, 0.7) if not dazed else Color(3, 2.5, 0.6))
	FX.squash(sprite, Vector2(1.08, 0.94), 0.1)
	if health <= 0:
		_die()


func _die() -> void:
	dead = true
	active = false
	move_dir = 0
	leaping = false
	_set_hitbox(false)
	collision_layer = 0
	sprite.speed_scale = 1.0
	sprite.modulate = Color.WHITE
	sprite.play("death")
	for m in minions:
		if is_instance_valid(m) and m.has_method("take_damage"):
			m.take_damage(999)
	for p in get_tree().get_nodes_in_group("boss_projectile"):
		p.queue_free()

	await get_tree().create_timer(0.12, true, false, true).timeout
	boom_sound.play()
	FX.shake(self, 5.0, 0.8)
	Engine.time_scale = 0.3
	await get_tree().create_timer(1.2, true, false, true).timeout
	Engine.time_scale = 1.0
	defeated.emit()
	await _wait(1.5)
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 1.0)
	t.tween_callback(queue_free)


func _wait(t: float) -> void:
	await get_tree().create_timer(t, false).timeout 


func _flash(c: Color) -> void:
	sprite.modulate = c
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.2)


func _face(d: float) -> void:
	if d == 0:
		return
	dir = d
	sprite.flip_h = dir < 0
	sprite.position.x = SPRITE_X * dir
	attack_box.scale.x = dir
	floor_ray.position.x = absf(floor_ray.position.x) * dir


func _face_player() -> void:
	if _player_alive():
		_face(signf(player.global_position.x - global_position.x))


func _in_range() -> bool:
	return _player_alive() and absf(player.global_position.x - global_position.x) <= attack_range * 1.2


func _play(anim: StringName) -> void:
	if sprite.animation != anim or not sprite.is_playing():
		sprite.play(anim)


func _player_alive() -> bool:
	return is_instance_valid(player) and not player.dead


func _alive_minions() -> int:
	minions = minions.filter(func(m): return is_instance_valid(m))
	return minions.size()
