extends Node2D

# @export var WORLD_SIZE := 1000.0

const TILE_SIZE := 64.0
const COLOR_A := Color(0.15, 0.15, 0.2)
const COLOR_B := Color(0.2, 0.2, 0.25)
const ENEMY_SCENE := preload("res://scenes/enemy/enemy.tscn")
const DEBUG_SPAWN_PANEL_SCENE := preload("res://scenes/debug/debug_spawn_panel.tscn")

var world_id: int = 0
var player: Player = null

func get_world_id() -> int:
	return world_id


func spawn_enemy_at(data: EnemyData, world_position: Vector2) -> void:
	# One-shot variant of Spawner._spawn_enemy() used by the debug panel.
	var enemy := ENEMY_SCENE.instantiate()
	enemy.setup(data)
	enemy.global_position = world_position
	add_child(enemy)

func setup(world_index: int, player_scene: PackedScene, player_color: Color) -> void:
	world_id = world_index
	player = player_scene.instantiate()
	player.position = $SpawnPoint.position
	player.setup(world_index, player_color)
	add_child(player)
	GameState.register_player(world_index, player)
	var fcn := preload("res://scenes/combat/floating_combat_numbers.tscn").instantiate()
	add_child(fcn)
	var hud := preload("res://scenes/hud/hud.tscn").instantiate()
	add_child(hud)
	hud.setup(player)
	if world_index == 0:
		add_child(DEBUG_SPAWN_PANEL_SCENE.instantiate())
	if world_index < GameState.cpu_players.size() and GameState.cpu_players[world_index]:
		InputManager.set_cpu_controlled(world_index, true)
		var cpu := CpuController.new()
		cpu.setup(player, world_index)
		add_child(cpu)


func on_player_died() -> void:
	GameState.on_player_died(world_id)
	player = null
