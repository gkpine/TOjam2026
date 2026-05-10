class_name SummonEnemyData
extends AbilityData

@export var enemy_type: EnemyData


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
	var angle := randf() * TAU
	var dist := enemy_type.target_range_px * 0.8
	var spawn_pos := target_player.global_position + Vector2(cos(angle), sin(angle)) * dist
	target_world.spawn_enemy_at(enemy_type, spawn_pos)
