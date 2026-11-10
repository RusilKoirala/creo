@tool
extends Area2D



const UPGRADES = preload("res://scripts/autoload/upgrades.gd")   # for names in the editor

@export_enum("double_jump", "air_dash", "heart", "dash_strike") var upgrade := "double_jump":
	set(value):
		upgrade = value
		_refresh()
@export var color := Color(0.55, 0.85, 1.0):
	set(value):
		color = value
		queue_redraw()

@onready var prompt: Label = $Prompt
@onready var sound: AudioStreamPlayer2D = $PickupSound

var time := 0.0
var player_near := false
var taken := false
var gem_y := -10.0
var gem_scale := 1.0


func _ready() -> void:
	_refresh()
	if Engine.is_editor_hint():
		return
	if _key() in SaveData.found_pickups or Upgrades.is_maxed(upgrade):
		queue_free()
		return
	body_entered.connect(func(b): if b.is_in_group("player"): _set_near(true))
	body_exited.connect(func(b): if b.is_in_group("player"): _set_near(false))


func _key() -> String:
	var scene := get_tree().current_scene
	return "%s::%s" % [scene.scene_file_path, scene.get_path_to(self)]


func _refresh() -> void:
	if not is_node_ready():
		return
	prompt.text = "[E] %s" % UPGRADES.DEFS[StringName(upgrade)].name
	queue_redraw()


func _process(delta: float) -> void:
	time += delta
	if not taken:
		gem_y = -12 + sin(time * 3.0) * 2.5
	queue_redraw()
	if Engine.is_editor_hint() or taken:
		return
	if player_near and Input.is_action_just_pressed("interact"):
		_collect()



func _draw() -> void:
	var pulse := 1.0 + sin(time * 4.0) * 0.15
	for i in 4:
		draw_circle(Vector2(0, gem_y), (12 - i * 2.5) * pulse * gem_scale, Color(color, 0.08 + i * 0.05))
	var s := 6.0 * gem_scale
	var pts := PackedVector2Array([
		Vector2(0, gem_y - s), Vector2(s * 0.75, gem_y),
		Vector2(0, gem_y + s), Vector2(-s * 0.75, gem_y)])
	draw_colored_polygon(pts, color)
	draw_polyline(pts + PackedVector2Array([pts[0]]), color.darkened(0.5), 1.0)
	draw_line(Vector2(-s * 0.3, gem_y - s * 0.3), Vector2(0, gem_y - s * 0.7), Color(1, 1, 1, 0.8), 1.0)


func _set_near(near: bool) -> void:
	player_near = near
	prompt.visible = near
	if near:
		prompt.scale = Vector2(0.6, 0.6)
		prompt.pivot_offset = prompt.size / 2
		create_tween().tween_property(prompt, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _collect() -> void:
	taken = true
	prompt.hide()
	SaveData.found_pickups.append(_key())
	Upgrades.grant(upgrade) 
	sound.play()
	var t := create_tween().set_parallel()
	t.tween_property(self, "gem_y", gem_y - 20, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "gem_scale", 2.0, 0.4)
	t.tween_property(self, "modulate:a", 0.0, 0.3).set_delay(0.25)
	await sound.finished
	queue_free()
