class_name SummonEnemyData
extends AbilityData


func needs_player_target() -> bool:
	return true


func apply_effect(caster: Character, target_player: Player = null) -> void:
	if target_player == null or not is_instance_valid(target_player):
		var targets: Array[Node] = []
		for p in GameState.players:
			if p != null and is_instance_valid(p) and p != caster and p is Player:
				targets.append(p)
		if targets.is_empty():
			return
		target_player = targets.pick_random() as Player
	var target_world := GameState.get_world(target_player.player_index)
	if target_world == null:
		return
	var spawner := target_world.get_node_or_null("Spawner") as Spawner
	if spawner == null or spawner.enemy_types.is_empty():
		return
	var enemy_data := spawner.enemy_types.pick_random() as EnemyData
	var angle := randf() * TAU
	var dist := enemy_data.target_range_px * 0.8
	var spawn_pos := target_player.global_position + Vector2(cos(angle), sin(angle)) * dist
	target_world.spawn_enemy_at(enemy_data, spawn_pos)
