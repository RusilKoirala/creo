extends Node

## Autoload "Checkpoint": where to respawn after dying in the current level.
## Survives reload_current_scene() (dying) but is wiped when you leave the
## level, finish it, or pick Restart in the pause menu.
##
## Coins grabbed before the checkpoint stay collected after a respawn; coins
## grabbed after it come back (so the coin count stays honest).

var scene_path := ""
var position := Vector2.ZERO
var flag_id := ""                       # which flag is lit
var saved_coins: Array[String] = []    # coin node paths banked at the checkpoint
var pending_coins: Array[String] = []  # picked up since the last checkpoint


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


## Called on respawn: anything not banked at the checkpoint is forgotten.
func on_respawn() -> void:
	pending_coins.clear()


func clear() -> void:
	scene_path = ""
	flag_id = ""
	saved_coins.clear()
	pending_coins.clear()
