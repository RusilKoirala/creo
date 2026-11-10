extends Node

## Autoload "Upgrades": permanent abilities. Bought in the shop with coins
## (level menu > Shop) or handed out for free by an UpgradePickup.
## Levels are saved in SaveData.upgrades.
##
## To add a new upgrade: add an entry to DEFS, then check
## Upgrades.has(&"your_id") / Upgrades.level(&"your_id") wherever it matters.

signal changed(id: StringName)
signal unlocked(id: StringName)   # bought or picked up, the HUD shows a toast

## costs: one price per level, so its size is also the max level.
## Set a cost to 0 to make that level pickup-only (can't be bought).
const DEFS := {
	&"double_jump": {
		"name": "Double Jump",
		"desc": "Jump again in mid air.",
		"costs": [30],
	},
	&"air_dash": {
		"name": "Air Dash",
		"desc": "Press Q in the air to dash. Once per jump.",
		"costs": [40],
	},
	&"heart": {
		"name": "Extra Heart",
		"desc": "+1 max health.",
		"costs": [20, 35, 50],
	},
	&"dash_strike": {
		"name": "Dash Strike",
		"desc": "Dashing makes you untouchable and hurts enemies you pass through.",
		"costs": [60],
	},
}


func _ready() -> void:
	SaveData.progress_reset.connect(func():
		for id in DEFS:
			changed.emit(id))


func ids() -> Array:
	return DEFS.keys()


func level(id: StringName) -> int:
	return int(SaveData.upgrades.get(String(id), 0))


func has(id: StringName) -> bool:
	return level(id) > 0


func max_level(id: StringName) -> int:
	return DEFS[id].costs.size()


func is_maxed(id: StringName) -> bool:
	return level(id) >= max_level(id)


func display_name(id: StringName) -> String:
	return DEFS[id].name


func description(id: StringName) -> String:
	return DEFS[id].desc


## Price of the next level, or -1 if maxed / not for sale.
func next_cost(id: StringName) -> int:
	if is_maxed(id):
		return -1
	var c: int = DEFS[id].costs[level(id)]
	return c if c > 0 else -1


func can_buy(id: StringName) -> bool:
	var c := next_cost(id)
	return c > 0 and SaveData.total_coins >= c


func buy(id: StringName) -> bool:
	if not can_buy(id):
		return false
	SaveData.total_coins -= next_cost(id)
	_level_up(id)
	return true


## Free level up (pickups, boss rewards).
func grant(id: StringName) -> void:
	if DEFS.has(id) and not is_maxed(id):
		_level_up(id)


func _level_up(id: StringName) -> void:
	SaveData.upgrades[String(id)] = level(id) + 1
	SaveData.save_game()
	changed.emit(id)
	unlocked.emit(id)
