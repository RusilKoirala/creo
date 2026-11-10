extends Control



const UI = preload("res://scripts/ui/ui_style.gd")
const COIN_TEXTURE = preload("res://assets/sprites/coin.png")
const BUY_SOUND = preload("res://assets/sounds/power_up.wav")

var coin_label: Label
var cards := {}         
var buy_player: AudioStreamPlayer


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.25, 0.2, 0.38)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	buy_player = AudioStreamPlayer.new()
	buy_player.stream = BUY_SOUND
	buy_player.bus = &"SFX"
	add_child(buy_player)

	var title := UI.label("SHOP", 56, UI.YELLOW)
	title.add_theme_color_override("font_outline_color", UI.DARK)
	title.add_theme_constant_override("outline_size", 12)
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.offset_left = -300
	title.offset_right = 300
	title.offset_top = 40
	add_child(title)

	_build_cards()
	_add_coin_counter()
	_add_back_button()
	_refresh()

	await get_tree().process_frame
	var buttons: Array = []
	for id in cards:
		buttons.append(cards[id].panel)
	UI.pop_in(buttons, 0.06)
	cards[cards.keys()[0]].button.grab_focus()


func _build_cards() -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_top = 70
	add_child(center)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 28)
	grid.add_theme_constant_override("v_separation", 28)
	center.add_child(grid)

	for id in Upgrades.ids():
		grid.add_child(_make_card(id))


func _make_card(id: StringName) -> Control:
	var panel := PanelContainer.new()
	var style := UI.box(Color(1, 0.95, 0.8), 14, 5)
	style.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(380, 0)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)

	var name_l := UI.label(Upgrades.display_name(id), 24, UI.DARK)
	name_l.add_theme_constant_override("shadow_offset_y", 0)
	col.add_child(name_l)

	var desc := UI.label(Upgrades.description(id), 14, Color(UI.DARK, 0.75))
	desc.add_theme_constant_override("shadow_offset_y", 0)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(340, 40)
	col.add_child(desc)

	
	var pips := HBoxContainer.new()
	pips.alignment = BoxContainer.ALIGNMENT_CENTER
	pips.add_theme_constant_override("separation", 6)
	col.add_child(pips)
	for i in Upgrades.max_level(id):
		var pip := Panel.new()
		pip.custom_minimum_size = Vector2(18, 18)
		pips.add_child(pip)

	var b := UI.button("", 20)
	b.custom_minimum_size = Vector2(340, 54)
	b.pressed.connect(_on_buy.bind(id))
	col.add_child(b)

	cards[id] = {"panel": panel, "button": b, "pips": pips}
	return panel


func _refresh() -> void:
	coin_label.text = str(SaveData.total_coins)
	for id in cards:
		var c: Dictionary = cards[id]
		var lvl := Upgrades.level(id)
		for i in c.pips.get_child_count():
			var pip: Panel = c.pips.get_child(i)
			pip.add_theme_stylebox_override("panel",
				UI.box(Color(0.35, 0.85, 0.4) if i < lvl else Color(UI.DARK, 0.25), 4, 0))
		var b: Button = c.button
		var cost := Upgrades.next_cost(id)
		if Upgrades.is_maxed(id):
			b.text = "OWNED" if Upgrades.max_level(id) == 1 else "MAXED"
			b.disabled = true
		elif cost < 0:
			b.text = "FIND IT IN A LEVEL"
			b.disabled = true
		else:
			b.text = "BUY  -  %d coins" % cost
			b.disabled = not Upgrades.can_buy(id)


func _on_buy(id: StringName) -> void:
	if not Upgrades.buy(id):
		return
	buy_player.play()
	var panel: Control = cards[id].panel
	panel.pivot_offset = panel.size / 2
	panel.scale = Vector2(1.08, 1.08)
	create_tween().tween_property(panel, "scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_refresh()


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

	var icon := TextureRect.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = COIN_TEXTURE
	atlas.region = Rect2(0, 0, 16, 16)
	icon.texture = atlas
	icon.custom_minimum_size = Vector2(40, 40)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.add_child(icon)

	coin_label = UI.label("0", 32, UI.YELLOW)
	row.add_child(coin_label)


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


func _go_back() -> void:
	SceneChanger.change_scene("res://scenes/ui/level_menu.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go_back()
