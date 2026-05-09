class_name UpgradeData
extends Resource

@export var upgrade_id: StringName = &""
@export var upgrade_name: String = ""
@export var description: String = ""
@export var stat_modifiers: Dictionary = {}
@export var relative_probability: float = 1.0


static func pick_weighted(pool: Array[UpgradeData], count: int) -> Array[UpgradeData]:
	var available := pool.duplicate()
	var result: Array[UpgradeData] = []
	for i in range(mini(count, available.size())):
		var total_weight := 0.0
		for upgrade in available:
			total_weight += upgrade.relative_probability
		var roll := randf() * total_weight
		var cumulative := 0.0
		for j in range(available.size()):
			cumulative += available[j].relative_probability
			if roll <= cumulative:
				result.append(available[j].duplicate())
				available.remove_at(j)
				break
	return result
