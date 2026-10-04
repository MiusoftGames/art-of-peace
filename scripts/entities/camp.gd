@tool
class_name ArmyCamp
extends Node2D
## Drag SpawnPoint in the editor to change the army's entry tile.

@export_range(1, 200) var max_health := 20
var health := 20
var defeated := false

@export_enum("Blue:0", "Red:1") var team := 0:
	set(value):
		team = value
		refresh_sprite()
@export var blue_texture: Texture2D = preload("res://assets/sprites/camp_blue.svg"):
	set(value):
		blue_texture = value
		refresh_sprite()
@export var red_texture: Texture2D = preload("res://assets/sprites/camp_red.svg"):
	set(value):
		red_texture = value
		refresh_sprite()

func _ready() -> void:
	health = max_health
	defeated = false
	refresh_sprite()
	refresh_health()

func take_damage(amount: int) -> bool:
	if defeated or amount <= 0:
		return false
	health = maxi(0, health - amount)
	defeated = health == 0
	refresh_health()
	return defeated

func refresh_health() -> void:
	var bar := get_node_or_null("HealthBar") as ProgressBar
	if bar != null:
		bar.max_value = max_health
		bar.value = health
	var description := get_node_or_null("Description") as Label
	if description != null:
		description.text = "DEFEATED" if defeated else "HP: %d / %d" % [health, max_health]
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite != null:
		sprite.modulate = Color(0.4, 0.4, 0.4) if defeated else Color.WHITE

func refresh_sprite() -> void:
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite != null:
		sprite.texture = blue_texture if team == 0 else red_texture
	var label := get_node_or_null("NameLabel") as Label
	if label != null:
		label.text = "BLUE CAMP" if team == 0 else "RED CAMP"

