extends Node


var scene_path := ""
var position := Vector2.ZERO
var flag_id := ""
var saved_coins: Array[String] = []
var pending_coins: Array[String] = []


func has_for(scene: Node) -> bool:
	return scene != null and scene_path != "" and scene_path == scene.scene_file_path


func activate(scene: Node, pos: Vector2, id: String) -> void:
	if scene_path != scene.scene_file_path:
		saved_coins.clear()
	scene_path = scene.scene_file_path
	position = pos
	flag_id = id
	saved_coins.append_array(pending_coins)
	pending_coins.clear()


func note_coin(coin: Node) -> void:
	var scene := get_tree().current_scene
	if scene:
		pending_coins.append(str(scene.get_path_to(coin)))


func on_respawn() -> void:
	pending_coins.clear()


func clear() -> void:
	scene_path = ""
	flag_id = ""
	saved_coins.clear()
	pending_coins.clear()
