class_name GuardData
extends AbilityData

@export var duration: float = 5.0


func execute(caster: Player) -> bool:
	caster.start_guard(duration)
	for upgrade in get_modifying_upgrades(caster):
		if upgrade.upgrade_id == &"damage_reflect":
			caster.is_reflecting_damage = true
			caster.damage_reflect_percent = upgrade.stat_modifiers.get("damage_reflect_percent", 0.0)
	return true
