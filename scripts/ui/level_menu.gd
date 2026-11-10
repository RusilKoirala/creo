extends Control

const UI = preload("res://scripts/ui/ui_style.gd")
const COIN_TEXTURE = preload("res://assets/sprites/coin.png")




const LEVELS := {
	1: "res://scenes/levels/level1.tscn",
	2: "res://scenes/levels/level2.tscn",
	3: "res://scenes/levels/level3.tscn",
	4: "res://scenes/levels/level4.tscn",
	5: "res://scenes/levels/level5.tscn",
}
const SLOTS := 5 

var cards: Array[Button] = []


func _ready() -> void:

	$Node2D.hide()
	$Node2D2.hide()

	_style_title()
	_build_grid()
	_add_coin_counter()
	_add_back_button()
	_add_shop_button()

	await get_tree().process_frame
	UI.pop_in(cards, 0.05)
	for c in cards:
		if not c.disabled:
			c.grab_focus()
			break


func _style_title() -> void:
	var title: Label = $Label
	title.text = "SELECT LEVEL"
	title.add_theme_font_override("font", UI.FONT)
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", UI.YELLOW)
	title.add_theme_color_override("font_outline_color", UI.DARK)
	title.add_theme_constant_override("outline_size", 12)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	title.add_theme_constant_override("shadow_offset_y", 6)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.offset_left = -400
	title.offset_right = 400


func _build_grid() -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_top = 60
	add_child(center)

	var grid := GridContainer.new()
	grid.columns = SLOTS
	grid.add_theme_constant_override("h_separation", 22)
	grid.add_theme_constant_override("v_separation", 28)
	center.add_child(grid)

	for level in range(1, SLOTS + 1):
		var card := _make_card(level)
		grid.add_child(card)
		cards.append(card)


func _make_card(level: int) -> Button:
	var exists := LEVELS.has(level)
	var unlocked := exists and level <= SaveData.unlocked_level
	var played := SaveData.best_coins.has(level)

	var card := UI.button("", 20)
	card.custom_minimum_size = Vector2(180, 130)
	card.disabled = not unlocked
	if played:
		# finished levels get a green border
		var done := UI.box(UI.YELLOW)
		done.border_color = Color(0.35, 0.85, 0.4)
		done.set_border_width_all(5)
		card.add_theme_stylebox_override("normal", done)
	card.pressed.connect(_on_level_pressed.bind(level))

	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 10)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(col)

	var num := UI.label("LEVEL %d" % level, 22, UI.DARK)
	num.remove_theme_color_override("font_shadow_color")
	num.add_theme_constant_override("shadow_offset_y", 0)
	col.add_child(num)

	if not exists:
		col.add_child(_small("coming soon"))
	elif not unlocked:
		col.add_child(_small("locked"))
	else:
		var total := _coins_in_level(LEVELS[level])
		var best = SaveData.best_coins.get(level, -1)
		var text := "- / %d" % total if best < 0 else "%d / %d" % [best, total]
		col.add_child(_coin_row(text, best >= 0 and best >= total))

	for n in col.get_children():
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return card


func _small(text: String) -> Label:
	var l := UI.label(text, 14, Color(UI.DARK, 0.6))
	l.add_theme_constant_override("shadow_offset_y", 0)
	return l


func _coin_row(text: String, perfect: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	row.add_child(_coin_icon(24))
	var l := UI.label(text, 18, Color(0.2, 0.6, 0.25) if perfect else UI.DARK)
	l.add_theme_constant_override("shadow_offset_y", 0)
	row.add_child(l)
	for n in row.get_children():
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return row


func _coin_icon(px: int) -> TextureRect:
	var icon := TextureRect.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = COIN_TEXTURE
	atlas.region = Rect2(0, 0, 16, 16)  
	icon.texture = atlas
	icon.custom_minimum_size = Vector2(px, px)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return icon



func _coins_in_level(path: String) -> int:
	var scene: PackedScene = load(path)
	if scene == null:
		return 0
	var state := scene.get_state()
	var n := 0
	for i in state.get_node_count():
		var p := str(state.get_node_path(i))
		if p.begins_with("./Coins/") or p.begins_with("Coins/"):
			n += 1
	return n


func _add_coin_counter() -> void:
	var panel := PanelContainer.new()
	var style := UI.box(UI.DARK, 14, 5)
	style.set_content_margin_all(12)
	style.border_color = UI.YELLOW
	style.set_border_width_all(3)
	panel.add_theme_stylebox_override("panel", style)
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.offset_left = -240
	panel.offset_right = -24
	panel.offset_top = 24
	add_child(panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(row)
	row.add_child(_coin_icon(40))

	var count := UI.label("0", 32, UI.YELLOW)
	row.add_child(count)

	# count up from 0 for a bit of flair
	var t := create_tween()
	t.tween_method(func(v: int): count.text = str(v), 0, SaveData.total_coins, 0.8) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _add_back_button() -> void:
	var back := UI.button("< Back", 20)
	back.custom_minimum_size = Vector2(160, 50)
	back.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	back.offset_left = 24
	back.offset_top = -74
	back.offset_bottom = -24
	back.offset_right = 184
	back.pressed.connect(_go_back)
	add_child(back)


func _add_shop_button() -> void:
	var shop := UI.button("Shop >", 20)
	shop.custom_minimum_size = Vector2(160, 50)
	shop.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	shop.offset_left = -184
	shop.offset_top = -74
	shop.offset_bottom = -24
	shop.offset_right = -24
	shop.pressed.connect(func(): SceneChanger.change_scene("res://scenes/ui/shop_menu.tscn"))
	add_child(shop)


func _on_level_pressed(level: int) -> void:
	SceneChanger.change_scene(LEVELS[level])

func _go_back() -> void:
	SceneChanger.change_scene("res://scenes/ui/main_menu.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go_back()
