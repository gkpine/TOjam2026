extends Node2D

var _bracket: Node2D


func setup(radius: float) -> void:
	_bracket = preload("res://scenes/ui/cursor_bracket.tscn").instantiate()
	add_child(_bracket)
	_bracket.wrap_rect(Rect2(-radius, -radius, radius * 1, radius * 1))


func _process(_delta: float) -> void:
	var enemy := get_parent() as Character
	if enemy == null:
		visible = false
		return
	var world := enemy.get_parent()
	var player = world.get("player") if world else null
	visible = player != null and is_instance_valid(player) and player.target == enemy
