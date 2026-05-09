class_name AbilityData
extends Resource

@export var ability_name: String = ""
@export var cooldown: float = 6.0
@export var icon: Texture2D
@export var animation: StringName = &""


func execute(caster: Player) -> bool:
	return false
