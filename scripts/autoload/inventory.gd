extends Node

## Autoload "Inventory" (scenes/autoload/inventory.tscn).
## Holds every item the player owns across levels. Starting items are set
## in the inspector on the Inventory scene.

signal items_changed
signal equipped_changed(item: ItemData)
signal item_added(item: ItemData)

@export var starting_items: Array[ItemData] = []

var items: Array[ItemData] = []
var equipped_index := 0


func _ready() -> void:
	SaveData.progress_reset.connect(_reload)
	_reload()


func _reload() -> void:
	items.clear()
	for it in starting_items:
		if it:
			items.append(it)
	for path in SaveData.owned_items:
		var it := load(path) as ItemData
		if it and not has(it):
			items.append(it)
	equipped_index = clampi(equipped_index, 0, maxi(items.size() - 1, 0))
	items_changed.emit()
	equipped_changed.emit(current())


func has(item: ItemData) -> bool:
	if item == null:
		return false
	for it in items:
		if it == item or (it.id != &"" and it.id == item.id):
			return true
	return false


func add(item: ItemData) -> void:
	if item == null or has(item):
		return
	items.append(item)
	if not item.resource_path in SaveData.owned_items:
		SaveData.owned_items.append(item.resource_path)
		SaveData.save_game()
	items_changed.emit()
	item_added.emit(item)
	equip(items.size() - 1)   # new toys get equipped right away


func current() -> ItemData:
	if items.is_empty():
		return null
	return items[equipped_index]


func equip(index: int) -> void:
	if index < 0 or index >= items.size() or index == equipped_index and current():
		return
	equipped_index = index
	equipped_changed.emit(current())


func cycle() -> void:
	if items.size() > 1:
		equip((equipped_index + 1) % items.size())
