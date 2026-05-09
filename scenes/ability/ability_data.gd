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


# Called by Character._process_casting when the cast bar fills. Receives a
# Character (Player or Enemy) — subclasses that only make sense for one or
# the other should type-check at the top.
func apply_effect(caster: Character) -> void:
	pass


# Optional override: return a Node2D to be parented to the caster for the
# duration of the cast (e.g. an AoE telegraph circle). Returned automatically
# when the cast ends, by Character._finish_cast / cancel_cast.
func make_cast_indicator(_caster: Character) -> Node2D:
	return null
