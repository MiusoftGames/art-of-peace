extends Node
## Death rules are independent of movement and visuals.

func resolve(game: Node) -> void:
	for i in range(game.soldiers.size()):
		var a: PeacePerson = game.soldiers[i]
		if a.dead:
			continue
		for j in range(i + 1, game.soldiers.size()):
			var b: PeacePerson = game.soldiers[j]
			if b.dead or (a.peaceful and b.peaceful) or (not a.peaceful and not b.peaceful and a.team == b.team):
				continue
			if a.position.distance_to(b.position) < game.settings.contact_distance:
				if not b.peaceful:
					a.dead = true
				if not a.peaceful:
					b.dead = true
				if a.dead:
					game.record_death(a)
				if b.dead:
					game.record_death(b)
				if a.dead:
					break
	for i in range(game.soldiers.size() - 1, -1, -1):
		if game.soldiers[i].dead:
			game.soldiers[i].queue_free()
			game.soldiers.remove_at(i)
