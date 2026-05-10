extends Node

signal player_position_changed(player_index: int, new_position: Vector2)
signal cross_world_event(source_player: int, target_player: int, event_data: Dictionary)
signal player_died(player_index: int)
signal winner_declared(winner_index: int)

const PLAYER_COLORS: Array[Color] = [Color.RED, Color.DODGER_BLUE, Color.GREEN, Color.YELLOW]

var player_count: int = 1
var worlds: Array[Node] = []
var players: Array[Node] = []
var player_data: Array[Dictionary] = []
var cpu_players: Array[bool] = []
var game_start_time_msec: int = 0


func reset() -> void:
	worlds.clear()
	players.clear()
	player_data.clear()
	game_start_time_msec = Time.get_ticks_msec()
	while cpu_players.size() < player_count:
		cpu_players.append(false)
	for i in range(player_count):
		player_data.append({
			"index": i,
			"color": PLAYER_COLORS[i],
			"position": Vector2.ZERO,
		})


func register_world(world_index: int, world_node: Node) -> void:
	while worlds.size() <= world_index:
		worlds.append(null)
	worlds[world_index] = world_node


func register_player(player_index: int, player_node: Node) -> void:
	while players.size() <= player_index:
		players.append(null)
	players[player_index] = player_node


func get_player_data(player_index: int) -> Dictionary:
	return player_data[player_index]


func get_world(world_index: int) -> Node:
	return worlds[world_index]


func update_player_position(player_index: int, position: Vector2) -> void:
	player_data[player_index]["position"] = position
	player_position_changed.emit(player_index, position)


func on_player_died(player_index: int) -> void:
	players[player_index] = null
	player_died.emit(player_index)
	_check_winner()


func get_survival_seconds() -> float:
	return float(Time.get_ticks_msec() - game_start_time_msec) / 1000.0


func _check_winner() -> void:
	var alive_indices: Array[int] = []
	for i in range(players.size()):
		if players[i] != null and is_instance_valid(players[i]):
			alive_indices.append(i)
	if alive_indices.size() == 1:
		winner_declared.emit(alive_indices[0])
