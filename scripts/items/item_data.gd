class_name ItemData
extends Resource

## One item the player can own (a weapon for now).
## Make a new one in the FileSystem dock: right click > New Resource > ItemData.

@export var id: StringName = &""
@export var display_name := "Item"
@export_multiline var description := ""
## Shown in the HUD slot and on the pickup in the world.
@export var icon: Texture2D
## Scene attached to the player's WeaponHolder when this item is equipped.
## Its root should use a script that extends Weapon.
@export var equip_scene: PackedScene
