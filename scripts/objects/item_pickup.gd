@tool
extends Area2D


@export var item: ItemData:
	set(value):
		item = value
		_refresh()

@onready var icon: Sprite2D = $Icon
@onready var glow: Sprite2D = $Glow
@onready var prompt: Label = $Prompt
@onready var sound: AudioStreamPlayer2D = $PickupSound

var time := 0.0
var player_near := false
var taken := false

func _ready() -> void:
	_refresh()
	if Engine.is_editor_hint():
		return
	if Inventory.has(item):
		queue_free()
		return
	body_entered.connect(func(b): if b.is_in_group("player"): _set_near(true))
	body_exited.connect(func(b): if b.is_in_group("player"): _set_near(false))


func _refresh() -> void:
	if not is_node_ready():
		return
	icon.texture = item.icon if item else null
	prompt.text = "[E] %s" % (item.display_name if item else "?")


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or taken:
		return
	time += delta
	icon.position.y = -10 + sin(time * 3.0) * 2.5
	glow.scale = Vector2.ONE * (1.0 + sin(time * 4.0) * 0.12)
	if player_near and Input.is_action_just_pressed("interact"):
		_collect()


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
	Inventory.add(item)
	sound.play()
	var t := create_tween().set_parallel()
	t.tween_property(icon, "position:y", icon.position.y - 20, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(icon, "scale", Vector2(2, 2), 0.4)
	t.tween_property(self, "modulate:a", 0.0, 0.3).set_delay(0.25)
	await sound.finished
	queue_free()
