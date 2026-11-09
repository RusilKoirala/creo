extends PanelContainer

## HUD health bar. Look lives in scenes/ui/health_bar.tscn — edit it there.
## The red fill drops instantly on a hit and a pale "trail" bar drains
## behind it, so you can see how much you just lost.

@export var full_color := Color(0.4, 0.85, 0.35)
@export var mid_color := Color(1, 0.75, 0.2)
@export var low_color := Color(0.95, 0.25, 0.25)

@onready var fill: ProgressBar = %Fill
@onready var trail: ProgressBar = %Trail
@onready var ticks: Control = %Ticks
@onready var value_label: Label = %Value

var max_health := 1
var _first := true
var _fill_style: StyleBoxFlat
var _pulse: Tween
var _home := Vector2.ZERO


func _ready() -> void:
	# own copy so recoloring doesn't touch the shared resource
	_fill_style = fill.get_theme_stylebox("fill").duplicate()
	fill.add_theme_stylebox_override("fill", _fill_style)
	ticks.draw.connect(_draw_ticks)
	resized.connect(func(): pivot_offset = size / 2)


func set_health(current: int, max_value: int) -> void:
	max_health = maxi(max_value, 1)
	current = clampi(current, 0, max_health)
	fill.max_value = max_health
	trail.max_value = max_health
	value_label.text = "%d/%d" % [current, max_health]
	ticks.queue_redraw()
	_recolor(float(current) / max_health)
	_set_pulse(current == 1 and max_health > 1)

	if _first:
		_first = false
		_home = position
		fill.value = current
		trail.value = current
		return

	if current < fill.value:
		# hit: snap fill, let the trail drain after a beat
		fill.value = current
		var t := create_tween()
		t.tween_interval(0.3)
		t.tween_property(trail, "value", current, 0.4) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		_shake()
		_flash(Color(1, 0.5, 0.5))
	elif current > fill.value:
		# heal: trail jumps, fill grows into it
		trail.value = current
		create_tween().tween_property(fill, "value", current, 0.3) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_flash(Color(0.6, 1, 0.6))


func _recolor(ratio: float) -> void:
	if ratio > 0.6:
		_fill_style.bg_color = full_color
	elif ratio > 0.34:
		_fill_style.bg_color = mid_color
	else:
		_fill_style.bg_color = low_color


func _shake() -> void:
	var t := create_tween()
	for i in 5:
		t.tween_property(self, "position", _home + Vector2(randf_range(-5, 5), randf_range(-3, 3)), 0.035)
	t.tween_property(self, "position", _home, 0.05)


func _flash(color: Color) -> void:
	self_modulate = color
	create_tween().tween_property(self, "self_modulate", Color.WHITE, 0.25)


# Gentle throb on the last heart's worth of health.
func _set_pulse(on: bool) -> void:
	if _pulse:
		_pulse.kill()
		_pulse = null
	scale = Vector2.ONE
	if on:
		_pulse = create_tween().set_loops()
		_pulse.tween_property(self, "scale", Vector2(1.06, 1.06), 0.35).set_trans(Tween.TRANS_SINE)
		_pulse.tween_property(self, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_SINE)


# Little dividers so each point of health reads as its own chunk.
func _draw_ticks() -> void:
	var w := ticks.size.x
	var h := ticks.size.y
	for i in range(1, max_health):
		var x := roundf(w * i / max_health)
		ticks.draw_line(Vector2(x, 2), Vector2(x, h - 2), Color(0.12, 0.1, 0.16, 0.9), 3.0)
