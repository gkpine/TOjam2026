# Architecture

## Core Concept

Each player exists in their own **separate instance of the world**. The screen is split into viewports, and each viewport contains a completely independent scene tree. Players never share a physics space or node tree. All cross-player interaction goes through the `GameState` singleton.

This matters because when you want to affect another player (deal damage, swap positions, stun), you are reaching across world boundaries. You never traverse another viewport's scene tree directly — you go through `GameState`.

## Project Layout

```
scenes/
  menu/         main_menu.tscn + .gd    Player count selection, starts game
  game/         game.tscn + .gd         Split screen setup, instantiates worlds
  world/        world.tscn + .gd        A single world instance (one per player)
  player/       player.tscn + .gd       CharacterBody2D, movement, colored circle
scripts/
  autoload/
    game_state.gd                       Shared state across all worlds (singleton)
    input_manager.gd                    Input map setup for 4 players (singleton)
```

## Runtime Scene Tree

When a 4-player game is running, the tree looks like this:

```
Root
  GameState                    (autoload)
  InputManager                 (autoload)
  Game                         (Control, full screen)
    SubViewportContainer_0     (top-left quadrant)
      SubViewport_0
        World_0                (independent scene tree)
          SpawnPoint
          Player_0             (CharacterBody2D, red)
            CollisionShape2D
            Camera2D
    SubViewportContainer_1     (top-right quadrant)
      SubViewport_1
        World_1
          Player_1             (blue)
            ...
    SubViewportContainer_2     (bottom-left)
      SubViewport_2
        World_2
          Player_2             (green)
            ...
    SubViewportContainer_3     (bottom-right)
      SubViewport_3
        World_3
          Player_3             (yellow)
            ...
    ColorRect                  (vertical separator)
    ColorRect                  (horizontal separator)
```

Each `SubViewport` is a fully isolated rendering and physics context. `World_0` and `World_1` know nothing about each other at the node level.

## Autoloads

### GameState (`scripts/autoload/game_state.gd`)

The central hub for all shared data. Anything that needs to be visible across worlds lives here.

**State:**
- `player_count` — set by the menu before the game starts
- `worlds: Array[Node]` — references to each World instance (indexed 0-3)
- `players: Array[Node]` — references to each Player node
- `player_data: Array[Dictionary]` — per-player state, synced every physics frame. Each entry currently holds `index`, `color`, and `position`. Future milestones add `health`, `stats`, etc.

**Signals:**
- `player_position_changed(player_index, new_position)` — emitted every frame by the player via `update_player_position()`
- `cross_world_event(source_player, target_player, event_data)` — reserved for P4 card abilities

**Key methods:**
- `reset()` — called by `game.gd` at the start of each game session. Clears all state and initializes `player_data`.
- `register_world(index, node)` / `register_player(index, node)` — called during world setup
- `get_world(index)` / `get_player_data(index)` — read access for cross-world logic
- `update_player_position(index, position)` — called by the player every physics frame

### InputManager (`scripts/autoload/input_manager.gd`)

Sets up Godot's `InputMap` programmatically in `_ready()`. Actions are named with a player prefix: `p1_move_up`, `p2_switch_target`, etc.

- Player 1 gets keyboard bindings (WASD, Space, 1-4) **and** controller device 0
- Players 2-4 get controller devices 1-3 only
- Each controller binding has its `device` property set to the specific player's controller index, so `p2_move_up` only responds to controller 1's left stick

**API used by game code:**
- `get_movement_vector(player_index) -> Vector2` — returns a normalized direction vector. Wraps `Input.get_vector()` with the correct action prefix.
- `is_action_just_pressed(player_index, action) -> bool` — checks a specific action for a specific player. The `action` parameter is the base name without prefix, e.g. `"switch_target"`, `"ability_1"`.

Input is **polled globally** (`Input.get_vector`), not handled through `_input()` events. This avoids SubViewport input routing issues entirely. The SubViewports have `handle_input_locally = false` so they don't interfere with polling.

## How Things Connect

### Game Startup Flow

1. `MainMenu` — user picks player count → sets `GameState.player_count` → scene changes to `game.tscn`
2. `Game._ready()` calls `GameState.reset()` to clear stale state
3. For each player, `game.gd` creates: `SubViewportContainer` → `SubViewport` → `World` instance
4. `World.setup()` instantiates a `Player` into itself, registers both with `GameState`
5. Each player's `Camera2D` automatically becomes the active camera for its own SubViewport

### Per-Frame Loop

Each `Player._physics_process()`:
1. Reads movement input via `InputManager.get_movement_vector(player_index)`
2. Sets `velocity` and calls `move_and_slide()`
3. Syncs position to `GameState.update_player_position()`

This means `GameState.player_data[i]["position"]` is always current for any player, readable from any world.

## How to Do Common Things

### Add something to a player's own world (e.g. enemies, items)

Add it as a child of the `World` node. The world scene (`scenes/world/world.tscn`) is instanced once per player, so anything you add there appears independently in each player's viewport.

```gdscript
# Inside world.gd
func spawn_enemy(enemy_scene: PackedScene, pos: Vector2) -> void:
    var enemy = enemy_scene.instantiate()
    enemy.position = pos
    add_child(enemy)
```

Each world has its own physics space, so enemies in World_0 cannot collide with Player_1 in World_1. They are completely separate.

### Read another player's state (e.g. for targeting, UI)

Go through `GameState`, never through the scene tree:

```gdscript
# Get player 2's position from anywhere
var p2_data := GameState.get_player_data(1)
var p2_position: Vector2 = p2_data["position"]
```

To add new shared state (health, status effects, etc.), add keys to the `player_data` dictionary in `GameState.reset()` and update them from the relevant scripts.

### Affect another player's world (e.g. card abilities)

Use the `cross_world_event` signal or call methods on the target world directly:

```gdscript
# Option A: Signal (decoupled, preferred for effects that multiple systems care about)
GameState.cross_world_event.emit(source_player_idx, target_player_idx, {
    "type": "damage",
    "amount": 25,
})

# Option B: Direct call (simpler for one-off effects)
var target_world = GameState.get_world(target_player_idx)
target_world.apply_effect(...)
```

For signals, the receiving world connects in its `_ready()`:
```gdscript
func _ready() -> void:
    GameState.cross_world_event.connect(_on_cross_world_event)

func _on_cross_world_event(source: int, target: int, data: Dictionary) -> void:
    if target != world_id:
        return
    # Handle the event in this world
```

### Add a new input action

1. Add the action name to `BUTTON_ACTIONS` (or `MOVEMENT_ACTIONS`) in `input_manager.gd`
2. Add the keyboard key to `KB_BINDINGS` (for player 1)
3. Add the controller button to `JOY_BUTTON_BINDINGS` (or axis to `STICK_AXES`)
4. The action is automatically registered for all 4 players as `p1_<name>` through `p4_<name>`
5. Read it with `InputManager.is_action_just_pressed(player_index, "your_action")`

### Add per-player UI (e.g. health bar, ability cooldowns)

Add UI nodes as children of the World or as an overlay within each SubViewport. Since each SubViewport is a self-contained rendering context, UI added inside it only appears on that player's screen.

For a **per-player overlay** (e.g. "You Died"):
```gdscript
# Inside world.gd — only this player's viewport shows it
var label = Label.new()
label.text = "You Died"
# Add to a CanvasLayer so it stays fixed on screen
var ui_layer = CanvasLayer.new()
ui_layer.add_child(label)
add_child(ui_layer)
```

For a **game-wide overlay** (e.g. "Player X Won"):
```gdscript
# Inside game.gd — on top of all viewports
var label = Label.new()
label.text = "Player %d Won!" % winner
add_child(label)  # Added to the Game Control node, above all SubViewportContainers
```

### Add player stats

Extend `player_data` in `GameState.reset()`:

```gdscript
player_data.append({
    "index": i,
    "color": PLAYER_COLORS[i],
    "position": Vector2.ZERO,
    "health": 100.0,
    "max_health": 100.0,
    "base_damage": 10.0,
    "strength": 0.0,
    "auto_attack_per_second": 1.0,
    "movement_speed": 200.0,
    "target_range_px": 200.0,
    "auto_attack_range_px": 100.0,
})
```

Then read/write from anywhere via `GameState.get_player_data(index)`. The player script should read `movement_speed` from here instead of its local `move_speed` export once stats are in place.

## Design Principles

1. **Worlds are isolated.** No node in World_0 should hold a reference to a node in World_1. Cross-world communication always goes through `GameState`.

2. **GameState owns shared data.** Position, health, stats — anything that another world might need to read or modify lives in `GameState.player_data`, not on the node. Nodes sync their local state to GameState each frame.

3. **Input is polled, not evented.** Use `InputManager.get_movement_vector()` and `InputManager.is_action_just_pressed()`. Don't override `_input()` or `_unhandled_input()` on gameplay nodes — it interacts badly with SubViewport input routing.

4. **Player index is the universal key.** Player 0's world is `GameState.get_world(0)`, their data is `GameState.get_player_data(0)`, their input is `InputManager.get_movement_vector(0)`, and their node is `GameState.players[0]`. Everything is indexed consistently.
