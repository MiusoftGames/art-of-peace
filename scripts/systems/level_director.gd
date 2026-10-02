extends RefCounted
## Random round goals and occasional reinforcements, tuned in PeaceSettings.
static func configure(game: Node) -> void:
	if game.level > game.settings.random_goal_after_level:
		game.goal = game.rng.randi_range(game.settings.random_goal_min, game.settings.maximum_rescue_goal)
	game.anomaly_remaining = game.rng.randi_range(1, 3)
	if not game.settings.vary_level_layout:
		return
	if game.level > game.settings.extra_camp_after_level and game.rng.randf() < game.settings.extra_camp_chance:
		var extra: ArmyCamp = preload("res://scenes/entities/army_camp.tscn").instantiate()
		extra.team = game.rng.randi_range(0, 1)
		game.get_node("Camps").add_child(extra)
	# Keep camp art in the clear part of the sidebars; entry markers track row changes.
	for team in range(2):
		var camps: Array[ArmyCamp] = game.get_camps(team)
		var first_row: int = game.rng.randi_range(6, 9)
		if camps.size() > 1:
			first_row = 6 if game.rng.randf() < 0.5 else 10
		for index in range(camps.size()):
			var camp: ArmyCamp = camps[index]
			var row: int = first_row if index == 0 else (10 if first_row == 6 else 6)
			camp.scale = Vector2(0.75, 0.75)
			camp.position = Vector2(75 if team == 0 else 1005, game.board.position.y + game.board.point(Vector2i(0, row)).y)
			var entry := Vector2i(0 if team == 0 else game.settings.grid_size.x - 1, row)
			camp.get_node("SpawnPoint").position = camp.to_local(game.board.to_global(game.board.point(entry)))
