extends RefCounted
## Repeatable centered village and mirrored gate positions for each level.
static func apply(game: Node) -> void:
	if not game.settings.vary_level_layout:
		return
	var occupied: Dictionary = {}
	for group in ["People", "Seeds", "Trees"]:
		for item in game.get_node("Board/" + group).get_children():
			occupied[game.board.cell_at(item.position)] = true
	occupied[game.spawn_cell(0)] = true
	occupied[game.spawn_cell(1)] = true
	var middle: int = floori(game.settings.grid_size.x / 2.0)
	var rows: Array[int] = []
	for y in range(1, game.settings.grid_size.y - 1):
		var clear := true
		for dx in range(-game.village.building_half_width, game.village.building_half_width + 1):
			if occupied.has(Vector2i(middle + dx, y)):
				clear = false
		if clear:
			rows.append(y)
	if not rows.is_empty():
		var home := Vector2i(middle, rows[(game.level - 1) % rows.size()])
		game.village.position = game.board.point(home)
		for dx in range(-game.village.building_half_width, game.village.building_half_width + 1):
			occupied[home + Vector2i(dx, 0)] = true
	var options: Array[Vector2i] = []
	for y in range(2, game.settings.grid_size.y - 2):
		for x in range(2, middle):
			var left := Vector2i(x, y)
			var right := Vector2i(game.settings.grid_size.x - 1 - x, y)
			if not occupied.has(left) and not occupied.has(right) and y != game.spawn_cell(0).y and y != game.spawn_cell(1).y:
				options.append(left)
	if options.is_empty():
		return
	var chosen := options[((game.level - 1) * 7) % options.size()]
	for gate in game.get_node("Board/Gates").get_children():
		if gate is PeaceGate:
			var cell := chosen if gate.team == 0 else Vector2i(game.settings.grid_size.x - 1 - chosen.x, chosen.y)
			gate.position = game.board.point(cell)
