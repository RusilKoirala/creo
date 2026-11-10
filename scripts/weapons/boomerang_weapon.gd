extends Weapon



@export var projectile: PackedScene
@export var spawn_offset := Vector2(12, -10)

var thrown: Node = null


func attack() -> void:
	if is_instance_valid(thrown) or projectile == null:
		return
	var b = projectile.instantiate()
	b.direction = Vector2(facing(), 0)
	b.player = player
	player.get_parent().add_child(b)
	b.global_position = player.global_position + Vector2(spawn_offset.x * facing(), spawn_offset.y)
	thrown = b
	FX.squash(player.sprite, Vector2(1.1, 0.9), 0.1)
