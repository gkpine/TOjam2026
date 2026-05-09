extends Node2D
class_name Spawner

@export var enemy_scene: PackedScene
@export var enemy_types: Array[EnemyData] = []
@export var spawn_radius: float = 300.0
@export var respawn_time: float = 2.0

var _timer: Timer
var _spawned_enemies: Array = []


func _ready() -> void:
	_timer = Timer.new()
	_timer.wait_time = respawn_time
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)
	_timer.start()
	_spawn_enemy.call_deferred()


func _on_timer_timeout() -> void:
	if _all_enemies_dead():
		_spawn_enemy()


func _all_enemies_dead() -> bool:
	_spawned_enemies = _spawned_enemies.filter(func(e): return is_instance_valid(e))
	return _spawned_enemies.is_empty()


func _spawn_enemy() -> void:
	if not enemy_scene:
		return
	var enemy := enemy_scene.instantiate()
	if not enemy_types.is_empty():
		enemy.setup(enemy_types.pick_random())
	var angle := randf() * TAU
	var dist := randf() * spawn_radius
	enemy.position = global_position + Vector2(cos(angle), sin(angle)) * dist
	get_parent().add_child(enemy)
	_spawned_enemies.append(enemy)
