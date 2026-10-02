# Art of Peace — survival prototype

Open `project.godot` in Godot 4.6 and press **F5**.

- Start paused with an empty forest and **five peaceful people in the middle**.
- Hover over golden seeds to collect; left-click empty tiles to plant trees for one seed. Right-click removes a tree without refunding seeds.
- **Space** starts/pauses, **R** restarts, and **F** switches between normal and double speed. You can collect and reshape the forest while paused.
- Reach **10 living peaceful people** to advance to level 2, then 20 for level 3, then 30, and so on. Levels advance automatically, preserving people, trees, seeds, and wave progress. Lifetime conversions do not count as living survivors.
- **Zero living peaceful people, or a destroyed village, means game over.** The old peace meter and fixed soldier limit are removed.
- Armies spawn endlessly in waves of 10 pairs. The first spawn waits five seconds; gaps shorten within each wave and across later waves, down to 0.65 seconds. Each wave has an eight-second break before the next wave's initial delay.
- Hostile armies primarily move toward the opposing camp; they do not chase peaceful people. On contact, a peaceful person dies and the attacker survives, including an attacker from their original team. Opposing hostile soldiers still fight each other; peaceful people never attack.
- Camps start with **20 HP**. A hostile soldier reaching an opposing camp's entry tile deals **1 damage each second**. The first camp to reach zero is defeated, and the other army wins the war.
- After victory, the defeated army's remaining hostile soldiers withdraw without adding deaths. Its peaceful people remain. Only the winning army continues spawning, one soldier per spawn pulse, and its normal soldiers/anomalies redirect toward the village. Existing wave timing continues.
- The village starts with **30 HP**. Winning soldiers that reach its center attack it; village destruction ends the game even if some peaceful people remain. Gates still convert normal soldiers, and anomalies still avoid both gates, so you can continue redirecting the invasion.
- Normal soldiers avoid trees and use shortest four-direction routes. A soldier with no available route cuts a blocking tree over two seconds.
- Passing through a soldier's matching peace gate turns them white and peaceful. They first travel to the **Peace Village at the top middle** and then stay around it.
- Peaceful villagers collect nearby seeds, carry one seed at a time, and return to the village. Your stock increases **on delivery**, not pickup. A killed carrier loses the undelivered seed. You can still collect seeds yourself by hovering.
- Every 20th spawned soldier is an **anomaly**, alternating camps. Orange rings and markers identify them. Their random detours lead toward the opposing camp. They ignore trees and destroy them on contact, but route around **both peace gates**. If forced onto a matching gate tile, the gate still converts them.

The game now uses separate editable Godot scenes, scripts, and transparent PNG placeholder sprites. The existing Godot MCP addon is preserved.

## Editing

Read [the editor guide](docs/EDITOR_GUIDE.md) for the scene tree, artwork replacement steps, Inspector settings, and code responsibilities.

- **Layout:** open `main.tscn`; move gates, camp SpawnPoint markers, seeds, and the five starting peaceful people.
- **Gameplay values:** edit `resources/default_settings.tres` in the Inspector.
- **Objects:** open the separate scenes in `scenes/entities/`. Blue/red soldiers, peaceful people, and anomalies are inherited variants of `person.tscn`.
- **Village:** move `Board/Village` in the main scene. Its Inspector exposes wander and forage radii; its separate `village.tscn` scene uses replaceable PNG art.
- **Camp/village health:** select their scene roots and edit Max Health. Attack interval and damage are in the shared settings resource under Camp and Village Attacks.
- **Sprites:** replace the PNG images in `assets/sprites/`, or assign new textures in the entity scenes. Matching SVGs are the original shape sources.
- **UI:** edit `scenes/ui/hud.tscn` and `resources/ui_theme.tres`.
- **Checks:** open `tests/run_checks.tscn` and press **F6**. The regression suite checks the real scenes and gameplay rules; **F5** runs the game again.
