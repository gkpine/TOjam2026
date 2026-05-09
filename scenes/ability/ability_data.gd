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


func apply_effect(caster: Player) -> void:
	pass
