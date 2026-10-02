@tool
class_name ArmyCamp
extends Node2D
## Drag SpawnPoint in the editor to change the army's entry tile.

@export_enum("Blue:0", "Red:1") var team := 0:
	set(value):
		team = value
		refresh_sprite()
@export var blue_texture: Texture2D = preload("res://assets/sprites/camp_blue.png"):
	set(value):
		blue_texture = value
		refresh_sprite()
@export var red_texture: Texture2D = preload("res://assets/sprites/camp_red.png"):
	set(value):
		red_texture = value
		refresh_sprite()

func _ready() -> void:
	refresh_sprite()

func refresh_sprite() -> void:
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite != null:
		sprite.texture = blue_texture if team == 0 else red_texture
	var label := get_node_or_null("NameLabel") as Label
	if label != null:
		label.text = "BLUE CAMP" if team == 0 else "RED CAMP"

