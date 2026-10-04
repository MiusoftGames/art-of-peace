@tool
class_name ForestBoard
extends Node2D
## The ground and placement cursor are scene nodes; only the grid is drawn.

@export var settings: PeaceSettings:
	set(value):
		if settings != null and settings.changed.is_connected(refresh_layout):
			settings.changed.disconnect(refresh_layout)
		settings = value
		if settings != null:
			settings.changed.connect(refresh_layout)
		refresh_layout()
@export var show_grid := true:
	set(value):
		show_grid = value
		queue_redraw()
@export var grid_color := Color(1, 1, 1, 0.08)

func _ready() -> void:
	refresh_layout()

func refresh_layout() -> void:
	if settings != null and is_inside_tree():
		$Ground.size = Vector2(settings.grid_size) * settings.cell_size
		$PlacementPreview.scale = Vector2.ONE * settings.cell_size / 40.0
	queue_redraw()

func point(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * settings.cell_size

func cell_at(local_position: Vector2) -> Vector2i:
	return Vector2i(floori(local_position.x / settings.cell_size), floori(local_position.y / settings.cell_size))

func inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < settings.grid_size.x and cell.y >= 0 and cell.y < settings.grid_size.y

func show_preview(cell: Vector2i, valid: bool, enabled: bool) -> void:
	$PlacementPreview.visible = inside(cell) and enabled
	$PlacementPreview.position = point(cell)
	$PlacementPreview.modulate = Color("e5ffcc") if valid else Color("ff9980")

func _draw() -> void:
	if settings == null or not show_grid:
		return
	var extent := Vector2(settings.grid_size) * settings.cell_size
	for x in range(settings.grid_size.x + 1):
		draw_line(Vector2(x * settings.cell_size, 0), Vector2(x * settings.cell_size, extent.y), grid_color)
	for y in range(settings.grid_size.y + 1):
		draw_line(Vector2(0, y * settings.cell_size), Vector2(extent.x, y * settings.cell_size), grid_color)
