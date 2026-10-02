extends RefCounted
## Random centered village and gates mirrored from opposite corners.
static func apply(game: Node) -> void:
	if not game.settings.vary_level_layout:
		return
	var occupied: Dictionary = {}
	for group in ["People", "Seeds", "Trees"]:
		for item in game.get_node("Board/" + group).get_children():
			occupied[game.board.cell_at(item.position)] = true
	for camp in game.get_node("Camps").get_children():
		if camp is ArmyCamp:
			occupied[game.camp_cell(camp)] = true
	var middle: int = floori(game.settings.grid_size.x / 2.0)
	var rows: Array[int] = []
	for y in range(1, game.settings.grid_size.y - 1):
		var clear := true
		for dx in range(-game.village.building_half_width, game.village.building_half_width + 1):
			if occupied.has(Vector2i(middle + dx, y)):
				clear = false
		if clear and (game.previous_layout.is_empty() or y != game.previous_layout[0].y):
			rows.append(y)
	if not rows.is_empty():
		var home := Vector2i(middle, rows[game.rng.randi_range(0, rows.size() - 1)])
		game.village.position = game.board.point(home)
		for dx in range(-game.village.building_half_width, game.village.building_half_width + 1):
			occupied[home + Vector2i(dx, 0)] = true
	var options: Array[Vector2i] = []
	# Zero-based column 2 is two cells inward from the left edge.
	var x := mini(2 + game.level - 1, maxi(2, middle - 2))
	for y in range(1, floori(game.settings.grid_size.y / 2.0)):
		var left := Vector2i(x, y)
		var right := Vector2i(game.settings.grid_size.x - 1 - x, game.settings.grid_size.y - 1 - y)
		if not occupied.has(left) and not occupied.has(right) and (game.previous_layout.size() < 2 or left.y != game.previous_layout[1].y):
			options.append(left)
	if options.is_empty():
		return
	var chosen := options[game.rng.randi_range(0, options.size() - 1)]
	for gate in game.get_node("Board/Gates").get_children():
		if gate is PeaceGate:
			var cell := chosen if gate.team == 0 else Vector2i(game.settings.grid_size.x - 1 - chosen.x, game.settings.grid_size.y - 1 - chosen.y)
			gate.position = game.board.point(cell)
