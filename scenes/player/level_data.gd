class_name LevelData
extends Resource

@export var max_level: int = 10
@export var xp_requirements: PackedInt32Array = [30, 50, 80, 120, 170, 230, 300, 380, 470]


func get_xp_required(current_level: int) -> float:
	var idx := current_level - 1
	if idx < 0 or idx >= xp_requirements.size():
		return 0.0
	return float(xp_requirements[idx])
