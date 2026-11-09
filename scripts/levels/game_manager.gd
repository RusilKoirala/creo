extends Node

var score = 0

@onready var coins_label: Label = $"../Labels/CoinsLabel"


func add_score():
	score+= 1
	coins_label.text = "You have collected "+ str(score) + " coins"
