extends CharacterBody2D
class_name Player

@export var move_speed: float = 200.0

var player_index: int = 0
var player_color: Color = Color.WHITE


func setup(index: int, color: Color) -> void:
	player_index = index
	player_color = color
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 16.0, player_color)


func _physics_process(_delta: float) -> void:
	var direction := InputManager.get_movement_vector(player_index)
	velocity = direction * move_speed
	move_and_slide()
	GameState.update_player_position(player_index, global_position)
