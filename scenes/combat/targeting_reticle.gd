extends Node2D


func _process(_delta: float) -> void:
	var enemy := get_parent() as Character
	if enemy == null:
		visible = false
		return
	var world := enemy.get_parent()
	var player = world.get("player") if world else null
	visible = player != null and is_instance_valid(player) and player.target == enemy


func _draw() -> void:
	draw_arc(Vector2.ZERO, 40, 0, TAU, 64, Color.RED, 2.0)
