extends Node2D
class_name SpawnRegion
## Marks a polygonal region where a fixed pool of enemy types spawns.
##
## Drop this into a world scene, draw the [Polygon2D] child to outline the
## region, and assign the [EnemyData] types that should appear inside it. The
## region keeps up to [member max_alive] enemies alive at any time and tops
## itself back up [member respawn_time] seconds after kills.
##
## Spawn positions are sampled uniformly inside the polygon (area-weighted
## triangle fan), so concave shapes work too.

const ENEMY_SCENE := preload("res://scenes/enemy/enemy.tscn")

@export var enemy_types: Array[EnemyData] = []
@export_range(0, 32) var max_alive: int = 3
@export var respawn_time: float = 2.0
## Pre-populate the region up to [member max_alive] on _ready instead of
## letting the timer fill it gradually.
@export var spawn_on_ready: bool = true
## Hide the editor-visible [Polygon2D] once the game starts running.
@export var hide_polygon_at_runtime: bool = true
## Reject sampled points that fail [code]World.is_spawnable_at()[/code] — by
## default this filters out points off the ground tilemap, on water, or
## overlapping a tree's collider. Turn off if you want the polygon to be the
## sole authority.
@export var validate_position: bool = true
## How many random points to try inside the polygon before giving up on a spawn.
## A polygon mostly covering valid ground rarely needs more than 4–8.
@export_range(1, 64) var max_sample_attempts: int = 16
## Pixel radius around the candidate point that must be free of static bodies
## (trees, etc.) for the point to be valid. Set to 0 to disable the obstacle
## check while keeping tile validation.
@export_range(0.0, 256.0, 1.0) var obstacle_clearance: float = 24.0

var _polygon: Polygon2D
var _alive: Array = []
var _timer: Timer
var _triangles: PackedInt32Array = PackedInt32Array()
var _triangle_cum_areas: Array[float] = []


func _ready() -> void:
	_polygon = get_node_or_null("Polygon2D") as Polygon2D
	if _polygon == null:
		push_warning("SpawnRegion '%s' has no Polygon2D child; it will not spawn anything." % name)
		return
	if hide_polygon_at_runtime:
		_polygon.visible = false
	_build_triangulation()
	_timer = Timer.new()
	_timer.wait_time = respawn_time
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)
	_timer.start()
	if spawn_on_ready:
		for i in max_alive:
			_spawn_enemy.call_deferred()


func _build_triangulation() -> void:
	_triangle_cum_areas.clear()
	var poly := _polygon.polygon
	if poly.size() < 3:
		_triangles = PackedInt32Array()
		return
	_triangles = Geometry2D.triangulate_polygon(poly)
	var total := 0.0
	var i := 0
	while i < _triangles.size():
		var a := poly[_triangles[i]]
		var b := poly[_triangles[i + 1]]
		var c := poly[_triangles[i + 2]]
		total += absf((b - a).cross(c - a)) * 0.5
		_triangle_cum_areas.append(total)
		i += 3


func _on_timer_timeout() -> void:
	_alive = _alive.filter(func(e): return is_instance_valid(e))
	if _alive.size() < max_alive:
		_spawn_enemy()


func _spawn_enemy() -> void:
	if enemy_types.is_empty() or _triangles.is_empty():
		return
	var world := get_parent()
	var pt := _find_spawn_point(world)
	if pt == Vector2.INF:
		push_warning("SpawnRegion '%s': no valid spawn point found in %d attempts; check that the polygon covers walkable ground." % [name, max_sample_attempts])
		return
	var data: EnemyData = enemy_types.pick_random() as EnemyData
	if data == null:
		return
	var enemy := ENEMY_SCENE.instantiate()
	enemy.setup(data)
	enemy.global_position = pt
	world.add_child(enemy)
	_alive.append(enemy)
	var exp_reward: float = data.exp_reward
	var loot: Dictionary = data.loot_table
	enemy.died.connect(func(_character: Character):
		if world.player and is_instance_valid(world.player):
			world.player.gain_experience(exp_reward)
			_roll_loot(loot, world.player)
	)


func _find_spawn_point(world: Node) -> Vector2:
	# Rejection sampling: pick uniform points in the polygon, ask the world
	# whether each one is spawnable, return the first that is. Returns
	# Vector2.INF if every attempt failed.
	var has_validator := validate_position and world != null and world.has_method("is_spawnable_at")
	for i in max_sample_attempts:
		var pt := _random_point_in_region()
		if not has_validator or world.is_spawnable_at(pt, obstacle_clearance):
			return pt
	return Vector2.INF


func _random_point_in_region() -> Vector2:
	if _triangle_cum_areas.is_empty():
		return global_position
	var total: float = _triangle_cum_areas[_triangle_cum_areas.size() - 1]
	if total <= 0.0:
		return _polygon.to_global(_polygon.polygon[0])
	var r := randf() * total
	var idx := 0
	while idx < _triangle_cum_areas.size() - 1 and _triangle_cum_areas[idx] < r:
		idx += 1
	var poly := _polygon.polygon
	var base := idx * 3
	var a := poly[_triangles[base]]
	var b := poly[_triangles[base + 1]]
	var c := poly[_triangles[base + 2]]
	# Uniform barycentric sampling: reflect the (u, v) point across the
	# diagonal so we cover the whole triangle, not just half of it.
	var u := randf()
	var v := randf()
	if u + v > 1.0:
		u = 1.0 - u
		v = 1.0 - v
	var local := a + (b - a) * u + (c - a) * v
	return _polygon.to_global(local)


func _roll_loot(loot: Dictionary, player: Player) -> void:
	if loot.is_empty():
		return
	var entries: Array = []
	for ability_id: StringName in loot:
		entries.append([ability_id, loot[ability_id] as float])
	entries.sort_custom(func(a, b): return a[1] < b[1])
	for entry in entries:
		if randf() < entry[1]:
			var path := "res://scenes/ability/types/%s.tres" % entry[0]
			var ability_res := load(path) as AbilityData
			if ability_res:
				var card := ability_res.duplicate() as AbilityData
				player.try_grant_card(card)
			return
