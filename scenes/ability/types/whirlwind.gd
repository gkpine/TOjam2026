class_name WhirlwindData
extends AbilityData

@export var range_px: float = 150.0
@export var base_damage: float = 5.0
@export var strength_multiplier: float = 2.0


func execute(caster: Player) -> bool:
	var damage := base_damage + caster.get_effective_stat("strength") * strength_multiplier
	var world := caster.get_parent() as Node2D
	if world == null:
		return false
	for child in world.get_children():
		if child is Enemy and is_instance_valid(child):
			if caster.global_position.distance_to(child.global_position) <= range_px:
				child.take_damage(damage, "ability", caster)
	return true
