# CLAUDE.md

This file is loaded automatically at the start of each Claude Code session. Keep it tight — it's a map and a list of gotchas, not a tutorial.

## Read first

**`architecture.md`** is the canonical deep-dive on the multiplayer/SubViewport architecture, the `GameState` autoload, and how cross-world communication works. Read it before changing anything that touches more than one file.

## What this is

A 1–4 player Godot 4.6 game (TOjam 2026 jam project). Each player runs in their **own SubViewport with their own scene tree and physics space** — they never share nodes. Cross-player state goes through the `GameState` autoload.

Main scene: `scenes/menu/main_menu.tscn`. Run with F5.

## Folder map

```
project.godot                      Engine config + autoload registry
architecture.md                    Canonical architecture doc — read it
scripts/autoload/
  game_state.gd                    Singleton: shared cross-world state
  input_manager.gd                 Singleton: 4-player input wiring (WASD + 3 controllers)
scripts/tree.gd                    Misc world objects
scenes/
  menu/main_menu.gd|.tscn          Player count select → loads game
  game/game.gd|.tscn               Builds split-screen SubViewports
  world/world.gd|.tscn             One independent world per player
    objects/tree.tscn              Scenery
  player/player.gd|.tscn           Per-player CharacterBody2D
  player/player_data.gd            Player stat resource
  player/level_data.gd|.tres       XP / level config
  character/character.gd           Base class for player + enemy (health, combat)
  enemy/enemy.gd|.tscn             Enemy node, takes EnemyData via setup()
  enemy/enemy_data.gd              Enemy stat Resource
  enemy/types/*.tres               12 enemy definitions (bear, troll, thief, …)
  spawner/spawn_region.gd|.tscn    Polygon-shaped region with its own enemy roster + respawn cap
  ability/ability_data.gd          Ability Resource
  ability/types/{smite,whirlwind}  Ability definitions
  combat/                          Floating damage numbers, targeting reticle
  hud/                             Per-player HUD (health bar, action bar)
  ui/                              Action bar slots, cursor brackets, status bar
  debug/debug_spawn_panel.gd|.tscn Dev tool — see "Debug" below
assets/enemies/<name>/<name>_{idle,attack,run}.png   Enemy sprite sheets
```

## Conventions

- **GDScript**, statically typed where practical. Tabs (not spaces) for indentation.
- Files are `snake_case.gd` and come in trios: `foo.gd` + `foo.tscn` + `foo.gd.uid`. The `.uid` is engine-generated; don't hand-edit.
- `class_name X` is used freely (e.g. `EnemyData`, `SpawnRegion`, `Player`, `Character`). Add it when you make a new globally-referenceable class.
- Data lives in **`.tres` Resources** (Godot's ScriptableObject equivalent). Enemy stats, ability stats, level curves are all `.tres`.
- Per-player UI = child of `World`. Game-wide overlays = child of `Game`. Don't mix.
- **GDScript warnings are errors.** Any `var x := <variant-returning-call>()` will fail to parse with "type inferred as Variant." Fixes:
  - `var x := node.get("prop") as TargetType`
  - `var n := get_node_or_null("Foo") as Foo` when the target has a `class_name`
  - Declare typed arrays (`Array[EnemyData]`) on params/returns so loop vars infer correctly

## Source-of-truth pointers

- **Enemy spawning:** the world holds one or more `SpawnRegion` instances (`scenes/world/world.tscn`, the default region is at line ~207). Each has its own `enemy_types: Array[EnemyData]`, `max_alive` cap, `respawn_time`, and a `Polygon2D` child outlining the area. Code that needs the union of "every enemy that can spawn in this world" calls `World.get_all_enemy_types()` (used by the debug spawn panel and the `SummonEnemy` ability) — don't reach for a single global spawner; there isn't one.
- **Input actions:** `scripts/autoload/input_manager.gd` — `BUTTON_ACTIONS`, `MOVEMENT_ACTIONS`, `KB_BINDINGS`, `JOY_BUTTON_BINDINGS`, `STICK_AXES`. Adding an action automatically registers it as `p1_<name>` … `p4_<name>`. Read with `InputManager.is_action_just_pressed(player_index, "<name>")`.
- **Cross-player state:** `scripts/autoload/game_state.gd` — extend `player_data` in `reset()` to add new shared fields.
- **Enemy sprite path scheme:** `res://assets/enemies/{enemy_name}/{enemy_name}_{idle|attack|run}.png`, with frame width = `EnemyData.frame_size` (default 192). See `scenes/enemy/enemy.gd:96-105`.

## Gotchas

- **No reaching across worlds.** A node in World 0 must not hold a reference to a node in World 1. Use `GameState` (positions, signals, `cross_world_event`).
- **Input is polled, not evented.** Use `InputManager.get_movement_vector()` / `is_action_just_pressed()`. Don't override `_input()` / `_unhandled_input()` on gameplay nodes — interacts badly with SubViewport routing. (Control-level UI events like clicks and drag-and-drop *do* still work — `handle_input_locally = false` lets the SubViewportContainer forward them.)
- **Only player 0 has keyboard.** Players 1–3 are controller-only (devices 1–3). Player 0 also has controller 0 in addition to keyboard.
- **Player index is the universal key.** Player 0's world is `GameState.get_world(0)`, data is `GameState.get_player_data(0)`, input is `InputManager.get_movement_vector(0)`.
- **Don't `await` on a freed node.** Standard Godot rule but easy to hit during cross-world signal handling.
- **Inspector "New X" creates an empty SubResource with default values, not a reference to the on-disk `.tres`.** This silently breaks logic that depends on the `.tres`'s overrides — e.g. `cast_time = 0` (the script default) instead of `1.5` (the `.tres` value) made an enemy AoE complete on frame 1, freeing the indicator before it could render. **Always drag the `.tres` from the FileSystem dock onto the inspector slot, or load it explicitly in code; never accept the editor's "New X" without setting every field.** When debugging "the values aren't what I set," check whether the parent `.tres` shows `behavior = SubResource(...)` (inline, broken) vs `behavior = ExtResource("...")` (proper reference).
- **Renderer is `forward_plus` on desktop** (set in `project.godot`). Switching to `gl_compatibility` on macOS triggers a known Godot 4.6 bug (#95294) where dynamically-added Sprite2D children of nodes inside a SubViewport silently fail to render. Mobile stays on `gl_compatibility`.
- **Cast UI / runtime-spawned visuals: configure the visual content BEFORE `add_child`, set position AFTER.** `Character.start_cast` (and any similar pattern) creates `StatusBar`/`AoeIndicator` nodes, calls their `setup()` to build child TextureRects / generate textures while the node is still detached from the tree, *then* `add_child`s into the world, *then* sets `global_position`. Doing `setup()` after `add_child` doesn't render reliably even on Forward+. Same rule applies if you add new cast-style abilities or runtime overlays.

## Where a new agent should start reading

In order:
1. `architecture.md`
2. `scripts/autoload/game_state.gd` — the shared-state contract
3. `scenes/game/game.gd` — split-screen viewport setup (entry point after the menu)
4. `scenes/world/world.gd` — what's inside one viewport
5. `scenes/player/player.gd` — per-player gameplay
6. `scenes/enemy/enemy.gd` + any file in `scenes/enemy/types/` — how data-driven enemies work

## Debug tooling

- **Spawn-an-enemy panel** (`scenes/debug/debug_spawn_panel.gd`): only mounted in player 0's world. Press `` ` `` (backtick) to toggle a scrollable panel of all 12 enemies; drag one onto the world to spawn at the cursor. Always available, in every build.
- **Spawn helper:** `World.spawn_enemy_at(data: EnemyData, world_position: Vector2)` — instantiates `enemy.tscn`, calls `setup(data)`, parents it to the world. Reuse this for any future debug or scripted spawning rather than duplicating spawner logic.

## Running / testing

- Open `project.godot` in Godot 4.6, press F5.
- There are no automated tests.
- Manual verification: pick player count in the menu, confirm each viewport renders independently, and that auto-spawned enemies engage the player.
