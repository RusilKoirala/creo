extends HBoxContainer

## Top-left item bar in the HUD. Builds one slot_scene per owned item
## and highlights the equipped one. Change the look in item_slot.tscn.

@export var slot_scene: PackedScene

var slots: Array = []


func _ready() -> void:
	Inventory.items_changed.connect(_rebuild)
	Inventory.equipped_changed.connect(func(_i): _highlight())
	_rebuild()


func _rebuild() -> void:
	for s in slots:
		s.queue_free()
	slots.clear()
	for i in Inventory.items.size():
		var slot = slot_scene.instantiate()
		add_child(slot)
		slot.setup(Inventory.items[i], i)
		slots.append(slot)
	_highlight.call_deferred()


func _highlight() -> void:
	for i in slots.size():
		slots[i].set_selected(i == Inventory.equipped_index)
