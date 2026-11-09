extends RefCounted

# Little helpers that make hits and pickups feel juicy.
# Call from anywhere: FX.shake(self), FX.hit_stop(self)


# Wiggle the active camera, fading out over `duration`.
static func shake(node: Node, strength := 2.0, duration := 0.2) -> void:
	var cam := node.get_viewport().get_camera_2d()
	if cam == null:
		return
	if not cam.has_meta("base_offset"):
		cam.set_meta("base_offset", cam.offset)
	var base: Vector2 = cam.get_meta("base_offset")

	# stop an older shake so they don't fight
	if cam.has_meta("shake_tween"):
		var old: Tween = cam.get_meta("shake_tween")
		if old and old.is_valid():
			old.kill()

	var tween := cam.create_tween().set_ignore_time_scale(true)
	cam.set_meta("shake_tween", tween)
	var steps := maxi(1, int(duration / 0.03))
	for i in steps:
		var falloff := 1.0 - float(i) / steps
		var wiggle := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * strength * falloff
		tween.tween_property(cam, "offset", base + wiggle, 0.03)
	tween.tween_property(cam, "offset", base, 0.03)


# Freeze the game for a split second so hits feel heavy.
static func hit_stop(node: Node, duration := 0.06, slow := 0.05) -> void:
	var tree := node.get_tree()
	Engine.time_scale = slow
	await tree.create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0


# Quick stretch then bounce back to normal size.
static func squash(sprite: Node2D, amount: Vector2, time := 0.15) -> void:
	if not sprite.has_meta("base_scale"):
		sprite.set_meta("base_scale", sprite.scale)
	var base: Vector2 = sprite.get_meta("base_scale")
	sprite.scale = base * amount
	var tween := sprite.create_tween()
	tween.tween_property(sprite, "scale", base, time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
