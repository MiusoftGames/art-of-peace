class_name GridPathfinding
extends RefCounted

const DIRECTIONS := [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]

## One BFS serves both single destinations and nearest reachable prey.
static func find_path(board: ForestBoard, from: Vector2i, targets: Dictionary, trees: Dictionary, ignore_trees := false) -> Array[Vector2i]:
	var frontier: Array[Vector2i] = [from]
	var previous: Dictionary = {from: from}
	var index := 0
	while index < frontier.size():
		var current := frontier[index]
		index += 1
		if targets.has(current):
			var path: Array[Vector2i] = []
			while current != from:
				path.push_front(current)
				current = previous[current]
			return path
		for direction in DIRECTIONS:
			var neighbor: Vector2i = current + direction
			if board.inside(neighbor) and not previous.has(neighbor) and (ignore_trees or not trees.has(neighbor)):
				previous[neighbor] = current
				frontier.append(neighbor)
	return []
