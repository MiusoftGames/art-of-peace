@tool
class_name PeaceVillage
extends Node2D
## Drag this scene in main.tscn to move the destination and delivery tile.

@export_range(1, 8) var wander_radius := 2
@export_range(1, 12) var forage_radius := 4
@export_range(0, 3) var building_half_width := 1
@export_range(1, 200) var max_health := 30

var health := 30

func _ready() -> void:
	health = max_health
	refresh_health()

func take_damage(amount: int) -> void:
	health = maxi(0, health - maxi(0, amount))
	refresh_health()

func refresh_health() -> void:
	var bar := get_node_or_null("HealthBar") as ProgressBar
	if bar != null:
		bar.max_value = max_health
		bar.value = health
	var label := get_node_or_null("HealthLabel") as Label
	if label != null:
		label.text = "HP: %d / %d" % [health, max_health]
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite != null:
		sprite.modulate = Color(0.4, 0.4, 0.4) if health == 0 else Color.WHITE

func home_cell(board: ForestBoard) -> Vector2i:
	return board.cell_at(position)

func is_building_cell(cell: Vector2i, board: ForestBoard) -> bool:
	var home := home_cell(board)
	return cell.y == home.y and absi(cell.x - home.x) <= building_half_width

func within_home_area(cell: Vector2i, board: ForestBoard) -> bool:
	return cell.distance_squared_to(home_cell(board)) <= wander_radius * wander_radius

func within_forage_area(cell: Vector2i, board: ForestBoard) -> bool:
	return cell.distance_squared_to(home_cell(board)) <= forage_radius * forage_radius
