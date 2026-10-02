# Art of Peace — survival prototype

Open `project.godot` in Godot 4.6 and press **F5**.

- Start paused with an empty forest and **five peaceful people in the middle**.
- Hover over golden seeds to collect; left-click empty tiles to plant trees for one seed. Right-click removes a tree without refunding seeds.
- **Space** starts/pauses, **R** restarts, and **F** switches between normal and double speed. You can collect and reshape the forest while paused.
- Reach **10 living peaceful people** to advance to level 2, then 20 for level 3, then 30, and so on. Levels advance automatically, preserving people, trees, seeds, and wave progress. Lifetime conversions do not count as living survivors.
- **Zero living peaceful people means game over.** The old peace meter and fixed soldier limit are removed.
- Armies spawn endlessly in waves of 10 pairs. The first spawn waits five seconds; gaps shorten within each wave and across later waves, down to 0.65 seconds. Each wave has an eight-second break before the next wave's initial delay.
- Both hostile armies hunt reachable peaceful people, including people converted from their own team. On contact, the peaceful person dies and the attacker survives. Opposing hostile soldiers still fight each other; peaceful people never attack.
- Normal soldiers avoid trees and use shortest four-direction routes. If peaceful people are unreachable, soldiers head toward the enemy camp. A soldier with no available route cuts a blocking tree over two seconds.
- Passing through a soldier's matching peace gate turns them white and peaceful. Peaceful people wander harmlessly.
- Every 20th spawned soldier is an **anomaly**, alternating camps. Orange rings and markers identify them. They hunt peaceful people using random short detours toward their destination, ignore trees and gates when choosing their route, and destroy trees on contact. They still become peaceful if they physically cross their matching gate.

The game now uses separate editable Godot scenes, scripts, and transparent PNG placeholder sprites. The existing Godot MCP addon is preserved.

## Editing

Read [the editor guide](docs/EDITOR_GUIDE.md) for the scene tree, artwork replacement steps, Inspector settings, and code responsibilities.

- **Layout:** open `main.tscn`; move gates, camp SpawnPoint markers, seeds, and the five starting peaceful people.
- **Gameplay values:** edit `resources/default_settings.tres` in the Inspector.
- **Objects:** open the separate scenes in `scenes/entities/`. Blue/red soldiers, peaceful people, and anomalies are inherited variants of `person.tscn`.
- **Sprites:** replace the PNG images in `assets/sprites/`, or assign new textures in the entity scenes. Matching SVGs are the original shape sources.
- **UI:** edit `scenes/ui/hud.tscn` and `resources/ui_theme.tres`.
- **Checks:** open `tests/run_checks.tscn` and press **F6**. The regression suite checks the real scenes and gameplay rules; **F5** runs the game again.
