extends CanvasLayer

@onready var bar = $HealthBar

func _ready() -> void:
	var player = get_parent()
	player.health_changed.connect(bar.set_health)



@onready var toast: Label = $Toast

func _enter_tree() -> void:
	Inventory.item_added.connect(_on_item_added)
	
	Upgrades.unlocked.connect(_on_upgrade_unlocked)



func _exit_tree() -> void:
	Inventory.item_added.disconnect(_on_item_added)
	Upgrades.unlocked.disconnect(_on_upgrade_unlocked)

func _on_item_added(item: ItemData) -> void:
	show_toast("Got %s!" % item.display_name, item.description)

func _on_upgrade_unlocked(id: StringName) -> void:
	show_toast("%s unlocked!" % Upgrades.display_name(id), Upgrades.description(id))

func show_toast(title: String, body := "") -> void:
	toast.text = title if body == "" else "%s\n%s" % [title, body]
	toast.show()
	toast.pivot_offset = toast.size / 2
	toast.modulate.a = 1.0
	toast.scale = Vector2(0.5, 0.5)
	var t := create_tween()
	t.tween_property(toast, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(2.5)
	t.tween_property(toast, "modulate:a", 0.0, 0.5)
	t.tween_callback(toast.hide)
