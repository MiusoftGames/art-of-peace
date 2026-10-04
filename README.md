# Art of Peace — rescue prototype

Open `project.godot` in Godot 4.6 and press **F5**.

- Click the centered **Start match** button to begin. The opening panel explains the goal and controls; the match stays frozen until you start.
- Hover over golden seeds to collect; left-click empty tiles to plant trees for one seed. Right-click removes a tree without refunding seeds.
- **Space** starts/pauses, **R** restarts, and **F** or the speed button cycles Normal (1x), Fast (2x), and Ultra (4x). You can collect and reshape the forest while paused.
- **Rescue 5 people to the village before either camp falls.** Arrivals count once, including the three starting peaceful people. Conversion alone does not count; later deaths do not subtract completed rescues.
- Success freezes the round and shows **Peace restored!** Press **Next level** to start a fresh map with a goal of 6, then 7, increasing by one through level 8; after level 8 each round chooses a random goal from 6–15. Each level begins paused with the authored three people, seeds, and empty forest. Later levels start with a gentle opening wave.
- **Either camp falling or zero peaceful survivors means failure.** Try again / R retries the current level. Space continues from the result screen.
- Soldiers always head for the opposing camp. Plant trees to redirect their shortest route through their matching gate. Start with **8 seeds**, steady **10-second spawn gaps**, and no anomalies before level 5.
- Armies spawn endlessly in waves of 10 spawn pulses, with a 10-second rest. Gaps stay constant within a wave and shorten by 1 second each new wave, down to 0.65 seconds. **Anomalies start at level 5**: one appears within the first two pulses, followed by random intervals of 3–8 soldiers. 
- People move at the original **48 pixels/second**; only spawn gaps accelerate between waves. Gates mirror from opposite corners (blue upper left, red lower right); the village stays centered and changes only its height. Every restart chooses fresh heights. Gates begin two columns from the sides, moving one column inward per level, capped two columns from the center. Generated layouts avoid starting seeds, people, trees, and camp entrances.
- Hostile armies primarily move toward the opposing camp; they do not chase peaceful people. On contact, a peaceful person dies and the attacker survives, including an attacker from their original team. Opposing hostile soldiers still fight each other; peaceful people never attack.
- After level 7, each camp sends random groups of **1–3 soldiers** per pulse. After level 8, each fresh round has a **35% chance** of one extra camp on a randomly chosen team (two blue/one red, or one blue/two red). Camp entry rows also change each round.
- Camps start with **20 HP**. A hostile soldier or anomaly at the opposing camp waits one attack interval, deals **exactly 1 damage**, then dies. Each attacker can damage a camp only once. Keep all camps standing until your rescue goal is reached. The round ends when a camp falls.
- Normal soldiers avoid trees and use shortest four-direction routes. A soldier with no available route cuts a blocking tree over two seconds.
- Passing through a soldier's matching peace gate turns them white and peaceful. They first travel to the **Peace Village** and then stay around it.
- Peaceful villagers collect reachable seeds anywhere on the map, carry one seed at a time, and return to the village. Your stock increases **on delivery**, not pickup. A killed carrier loses the undelivered seed. You can still collect seeds yourself by hovering.
- From level 5, occasional randomly spaced soldiers are **anomalies**. Orange rings and markers identify them. Their random detours lead toward the opposing camp. They ignore trees and destroy them on contact, but route around **both peace gates**. If forced onto a matching gate tile, the gate still converts them.

The board is 21% larger on screen, with a single 48-pixel HUD and a small controls hint. Characters use clean vector artwork with outlines matching the props, and the board has a faint white grid. Trees, seeds, gates, camps, and village use matching flat-color SVGs with bold outlines. Walking sways gently, planted trees pop in, and attacks show a small sword swing. Kenney effects cover collection, planting, chopping, sword attacks, conversion, and round results; **Sound on/off** retains your choice across rounds. Licenses are in `assets/audio/`.

## itch.io Web release

Export with `godot --headless --path . --export-release Web release/web/index.html`, then run `python tools/package_itch.py` after preparing the cover and screenshots in `release/itch-kit/`. Upload the inner `art-of-peace-web.zip` as a browser-playable HTML game. Page copy and settings are in `docs/ITCH-IO.txt`. The complete kit is `release/itch-upload-kit.zip`.

## Editing the game

Read [the editor guide](docs/EDITOR_GUIDE.md) for the scene tree, artwork replacement steps, Inspector settings, and code responsibilities.

- **Layout:** open `main.tscn`; move gates, camp SpawnPoint markers, seeds, and the three starting peaceful people.
- **Gameplay values:** edit `resources/default_settings.tres` in the Inspector.
- **Objects:** open the separate scenes in `scenes/entities/`. Blue/red soldiers, peaceful people, and anomalies are inherited variants of `person.tscn`.
- **Village:** move `Board/Village` in the main scene. Its Inspector exposes wander and forage radii; its separate `village.tscn` scene uses replaceable PNG art.
- **Camp health:** select their scene roots and edit Max Health. Attack interval and damage are in the shared settings resource under Camp Attacks.
- **Sprites:** characters and props use matching editable SVGs in `assets/sprites/`. Character textures are assigned in `scripts/entities/person.gd`. `python tools/polish_assets.py` rebuilds the sprites and minimal HUD scene.
- **UI:** edit `scenes/ui/hud.tscn` and `resources/ui_theme.tres`.
- **Checks:** open `tests/run_checks.tscn` and press **F6**. The regression suite checks the real scenes and gameplay rules; **F5** runs the game again.
