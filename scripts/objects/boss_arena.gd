class_name BossArena
extends Area2D



signal fight_started
signal fight_won

const FX = preload("res://scripts/utils/fx.gd")

@export var boss: Node2D
@export var rewards: Array[Node] = []

@export var fight_zoom := 3.8

@export var boss_music: AudioStream
@export var intro_delay := 0.7

var started := false
var bar: BossBar
var cam: Camera2D
var old_zoom := Vector2.ONE
var old_music: AudioStream


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2  
	body_entered.connect(_on_body_entered)
	for n in rewards:
		_set_active(n, false)
	if boss == null:
		await get_tree().process_frame
		boss = get_tree().get_first_node_in_group("boss")
	if boss:
		boss.defeated.connect(_on_boss_defeated)


func _gates() -> Array:
	return get_children().filter(func(c): return c.has_method("close") and c.has_method("open"))


func _on_body_entered(body: Node) -> void:
	if started or boss == null or not body.is_in_group("player"):
		return
	started = true
	for g in _gates():
		g.close()
	FX.shake(self, 2.0, 0.2)

	cam = get_viewport().get_camera_2d()
	if cam and fight_zoom > 0:
		old_zoom = cam.zoom
		cam.create_tween().tween_property(cam, "zoom", Vector2.ONE * fight_zoom, 1.0) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	if boss_music:
		old_music = Music.stream
		Music.stream = boss_music
		Music.play()

	await get_tree().create_timer(intro_delay, false).timeout
	bar = BossBar.create(boss.boss_name, boss.max_health)
	add_child(bar)
	boss.health_changed.connect(bar.set_health)
	boss.phase_changed.connect(func(_p): bar.enter_phase_two())
	boss.start_fight()
	fight_started.emit()


func _on_boss_defeated() -> void:
	if bar:
		bar.defeated()
	for g in _gates():
		g.open()
	if cam and fight_zoom > 0 and is_instance_valid(cam):
		cam.create_tween().tween_property(cam, "zoom", old_zoom, 1.5) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if old_music:
		Music.stream = old_music
		Music.play()
	for n in rewards:
		_set_active(n, true)
		if n is Node2D:
			var target: Vector2 = n.scale
			n.scale = Vector2.ZERO
			n.create_tween().tween_property(n, "scale", target, 0.4) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	fight_won.emit()



func _set_active(n: Node, on: bool) -> void:
	if n == null:
		return
	n.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
	if n is CanvasItem:
		n.visible = on
