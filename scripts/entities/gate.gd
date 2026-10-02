@tool
class_name PeaceGate
extends Node2D

@export_enum("Blue:0", "Red:1") var team := 0:
	set(value):
		team = value
		refresh_sprite()
@export var blue_texture: Texture2D = preload("res://assets/sprites/gate_blue.png"):
	set(value):
		blue_texture = value
		refresh_sprite()
@export var red_texture: Texture2D = preload("res://assets/sprites/gate_red.png"):
	set(value):
		red_texture = value
		refresh_sprite()

func _ready() -> void:
	refresh_sprite()

func refresh_sprite() -> void:
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite != null:
		sprite.texture = blue_texture if team == 0 else red_texture

