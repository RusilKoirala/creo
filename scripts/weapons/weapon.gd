class_name Weapon
extends Node2D

const FX = preload("res://scripts/utils/fx.gd")

## Base for anything the player can hold. The player puts the equipped
## item's scene under its WeaponHolder and calls attack() when F is pressed.
## WeaponHolder is flipped with the player, so build weapons facing RIGHT.

var player   ## the Player node (set by the player when equipping)
var item: ItemData


func attack() -> void:
	pass


## Direction the player is looking: 1 = right, -1 = left.
func facing() -> float:
	return -1.0 if player and player.sprite.flip_h else 1.0
