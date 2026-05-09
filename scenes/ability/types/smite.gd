class_name SmiteData
extends AbilityData

@export var base_damage: float = 50.0


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
	var damage := base_damage + caster.get_effective_stat("strength")
	target_player.take_damage(damage, "ability", caster)
