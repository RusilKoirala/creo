class_name Weapon
extends Node2D

const FX = preload("res://scripts/utils/fx.gd")



var player  
var item: ItemData


func attack() -> void:
	pass



func facing() -> float:
	return -1.0 if player and player.sprite.flip_h else 1.0
