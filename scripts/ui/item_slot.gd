extends Panel

## One square in the HUD inventory bar. Looks are set in item_slot.tscn.

@export var normal_style: StyleBox
@export var selected_style: StyleBox

@onready var icon: TextureRect = $Icon
@onready var key_label: Label = $Key


func setup(item: ItemData, index: int) -> void:
	icon.texture = item.icon
	key_label.text = str(index + 1)
	tooltip_text = item.display_name


func set_selected(selected: bool) -> void:
	add_theme_stylebox_override("panel", selected_style if selected else normal_style)
	pivot_offset = size / 2
	if selected:
		scale = Vector2(1.18, 1.18)
		create_tween().tween_property(self, "scale", Vector2.ONE * 1.08, 0.15).set_trans(Tween.TRANS_BACK)
	else:
		scale = Vector2.ONE
	icon.modulate = Color.WHITE if selected else Color(1, 1, 1, 0.7)
