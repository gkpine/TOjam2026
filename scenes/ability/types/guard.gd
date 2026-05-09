class_name GuardData
extends AbilityData

@export var duration: float = 5.0


func execute(caster: Player) -> bool:
	caster.start_guard(duration)
	return true
