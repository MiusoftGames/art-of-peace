extends Node

var remaining := 0.0

func advance(delta: float, game: Node) -> void:
	remaining += delta
	if remaining >= game.settings.seed_spawn_seconds:
		remaining = 0.0
		game.spawn_seed()
