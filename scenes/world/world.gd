extends Node2D

# @export var WORLD_SIZE := 1000.0

const TILE_SIZE := 64.0
const COLOR_A := Color(0.15, 0.15, 0.2)
const COLOR_B := Color(0.2, 0.2, 0.25)
const ENEMY_SCENE := preload("res://scenes/enemy/enemy.tscn")
const DEBUG_SPAWN_PANEL_SCENE := preload("res://scenes/debug/debug_spawn_panel.tscn")

var world_id: int = 0
var player: Player = null

@onready var _ground_tilemap: TileMapLayer = get_node_or_null("Map/GroundTileMapLayer") as TileMapLayer
@onready var _water_tilemap: TileMapLayer = get_node_or_null("Map/WaterTileMapLayer") as TileMapLayer


func get_world_id() -> int:
	return world_id


func is_spawnable_at(world_pos: Vector2) -> bool:
	# A point is spawnable if it sits on a Ground tile and not on a Water tile.
	# Returns true when either layer is missing — falls back to "trust the
	# region" rather than blocking everything.
	if _ground_tilemap != null:
		var ground_cell := _ground_tilemap.local_to_map(_ground_tilemap.to_local(world_pos))
		if _ground_tilemap.get_cell_source_id(ground_cell) == -1:
			return false
	if _water_tilemap != null:
		var water_cell := _water_tilemap.local_to_map(_water_tilemap.to_local(world_pos))
		if _water_tilemap.get_cell_source_id(water_cell) != -1:
			return false
	return true


func spawn_enemy_at(data: EnemyData, world_position: Vector2) -> void:
	# One-shot helper used by the debug panel and the SummonEnemy ability.
	# Bypasses SpawnRegion bookkeeping — these enemies don't count against any
	# region's alive cap and don't drop loot on death.
	var enemy := ENEMY_SCENE.instantiate()
	enemy.setup(data)
	enemy.global_position = world_position
	add_child(enemy)


func get_all_enemy_types() -> Array[EnemyData]:
	# Union of every SpawnRegion's enemy_types in this world. Used by callers
	# (SummonEnemy ability, debug spawn panel) that need the full roster of
	# enemies that can appear in a given player's world.
	var seen := {}
	var result: Array[EnemyData] = []
	for region in find_children("*", "SpawnRegion", true, false):
		for ed in (region as SpawnRegion).enemy_types:
			if ed != null and not seen.has(ed):
				seen[ed] = true
				result.append(ed)
	return result

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


func on_player_died() -> void:
	player = null
