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
var _clearance_query: PhysicsShapeQueryParameters2D
var _clearance_shape: CircleShape2D


func get_world_id() -> int:
	return world_id


func is_spawnable_at(world_pos: Vector2, clearance_radius: float = 24.0) -> bool:
	return describe_spawn_failure(world_pos, clearance_radius) == ""


func describe_spawn_failure(world_pos: Vector2, clearance_radius: float = 24.0) -> String:
	# Returns "" if the point is spawnable, otherwise one of "off_ground",
	# "on_water", or "blocked" describing which check rejected it. A point is
	# spawnable if it sits on a Ground tile, is not on a Water tile, and has
	# no static body (e.g. a tree's StaticBody2D) within `clearance_radius`
	# pixels. Each check is fail-open: a missing tile layer or absent World2D
	# is treated as "no opinion" rather than blocking.
	if _ground_tilemap != null:
		var ground_cell := _ground_tilemap.local_to_map(_ground_tilemap.to_local(world_pos))
		if _ground_tilemap.get_cell_source_id(ground_cell) == -1:
			return "off_ground"
	if _water_tilemap != null:
		var water_cell := _water_tilemap.local_to_map(_water_tilemap.to_local(world_pos))
		if _water_tilemap.get_cell_source_id(water_cell) != -1:
			return "on_water"
	if clearance_radius > 0.0:
		var w2d := get_world_2d()
		if w2d != null and w2d.direct_space_state != null:
			if _clearance_query == null:
				_clearance_shape = CircleShape2D.new()
				_clearance_query = PhysicsShapeQueryParameters2D.new()
				_clearance_query.shape = _clearance_shape
				_clearance_query.collide_with_areas = false
				_clearance_query.collide_with_bodies = true
				# World layer (1) only — trees and other static geometry block
				# spawns, but other enemies and the player do not. Without this
				# mask, overlapping SpawnRegions starve each other once one fills
				# up because the existing mob cluster rejects further attempts.
				_clearance_query.collision_mask = 1
			_clearance_shape.radius = clearance_radius
			_clearance_query.transform = Transform2D(0.0, world_pos)
			if not w2d.direct_space_state.intersect_shape(_clearance_query, 1).is_empty():
				return "blocked"
	return ""


func spawn_enemy_at(data: EnemyData, world_position: Vector2) -> Enemy:
	# One-shot helper used by the debug panel, the SummonEnemy ability, and
	# the shepherd behavior (which tracks the returned minion in its pool).
	# Bypasses SpawnRegion bookkeeping — these enemies don't count against any
	# region's alive cap and don't drop loot on death.
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.setup(data)
	enemy.global_position = world_position
	add_child(enemy)
	return enemy


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
	if world_index < GameState.cpu_players.size() and GameState.cpu_players[world_index]:
		InputManager.set_cpu_controlled(world_index, true)
		var cpu := CpuController.new()
		cpu.setup(player, world_index)
		add_child(cpu)


func on_player_died() -> void:
	GameState.on_player_died(world_id)
	player = null
