extends Weapon



@export var swing_damage := 1
@export var heavy_damage := 2
@export var spin_damage := 1
@export var knockback := 1.0
@export var combo_window := 0.35   
@export var spin_float := -90.0   
@export var hit_effect: PackedScene

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var hitbox: Area2D = $Hitbox
@onready var whoosh: AudioStreamPlayer2D = $Whoosh
@onready var hit_sound: AudioStreamPlayer2D = $HitSound

var busy := false
var queued := false
var next_is_heavy := false
var damage := 1
var hit_this_swing: Array = []
var last_swing_end := -1000.0


func _ready() -> void:
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	anim.animation_finished.connect(_on_animation_finished)
	anim.play("RESET")


func attack() -> void:
	if busy:
		queued = true   # buffer the press so combos feel snappy
		return
	_start_attack()


func _start_attack() -> void:
	busy = true
	hit_this_swing.clear()
	var now := Time.get_ticks_msec() / 1000.0
	if now - last_swing_end > combo_window:
		next_is_heavy = false

	var anim_name: String
	if not player.is_on_floor():
		anim_name = "spin"
		damage = spin_damage
		player.velocity.y = minf(player.velocity.y, spin_float)
	elif next_is_heavy:
		anim_name = "heavy"
		damage = heavy_damage
		next_is_heavy = false
	else:
		anim_name = "swing"
		damage = swing_damage
		next_is_heavy = true

	whoosh.pitch_scale = randf_range(0.55, 0.7) if anim_name == "heavy" else randf_range(0.8, 1.0)
	whoosh.play()
	anim.stop()
	anim.play(anim_name)


func _on_animation_finished(_name: StringName) -> void:
	busy = false
	last_swing_end = Time.get_ticks_msec() / 1000.0
	if queued:
		queued = false
		_start_attack()


func _on_hitbox_body_entered(body: Node) -> void:
	if body == player or body in hit_this_swing:
		return
	if not body.has_method("take_damage"):
		return
	hit_this_swing.append(body)
	body.take_damage(damage, player.global_position)

	hit_sound.pitch_scale = randf_range(0.9, 1.2)
	hit_sound.play()
	FX.hit_stop(self, 0.04 + 0.03 * damage)
	FX.shake(self, 1.5 * damage, 0.15)

	if hit_effect:
		var fx = hit_effect.instantiate()
		get_tree().current_scene.add_child(fx)
		fx.global_position = body.global_position + Vector2(0, -10)
		fx.rotation = randf_range(-0.6, 0.6)
		fx.scale.x *= facing()



func _clear_hits() -> void:
	hit_this_swing.clear()
