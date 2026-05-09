class_name AbilityData
extends Resource

@export var ability_id: StringName = &""
@export var ability_name: String = ""
@export var cooldown: float = 6.0
@export var icon: Texture2D
@export var animation: StringName = &""
@export var is_card: bool = false
@export var num_charges: int = -1
@export var cast_time: float = 0.0


func execute(caster: Player) -> bool:
	return false


func needs_player_target() -> bool:
	return false


# Called by Character._process_casting when the cast bar fills. Receives a
# Character (Player or Enemy) and an optional Player target (used by player-
# vs-player abilities like Smite). Subclasses that only make sense for one
# side should type-check at the top.
func apply_effect(caster: Character, target_player: Player = null) -> void:
	pass


# Optional override: return a Node2D to be parented to the caster for the
# duration of the cast (e.g. an AoE telegraph circle). Freed automatically
# by Character._finish_cast / cancel_cast.
func make_cast_indicator(_caster: Character) -> Node2D:
	return null


func get_modifying_upgrades(caster: Character) -> Array:
	var result := []
	for upgrade in caster.upgrades:
		if upgrade.modify_ability_id == ability_id:
			result.append(upgrade)
	return result
