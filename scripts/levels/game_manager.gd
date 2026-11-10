extends Node

var score = 0

@onready var coins_label: Label = $"../Labels/CoinsLabel"



func _ready() -> void:
	if not Checkpoint.has_for(get_tree().current_scene):
		return
	_restore_coins.call_deferred()


func _restore_coins() -> void:
	var scene := get_tree().current_scene
	for path in Checkpoint.saved_coins:
		var coin := scene.get_node_or_null(path)
		if coin:
			coin.queue_free()
			score += 1
	if score > 0:
		coins_label.text = "You have collected " + str(score) + " coins"


func add_score():
	score+= 1
	coins_label.text = "You have collected "+ str(score) + " coins"
