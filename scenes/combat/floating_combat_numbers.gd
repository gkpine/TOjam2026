extends Node2D

@export var animation_duration_seconds: float = 1.0
@export var bounce_scale: float = 1.3
@export var bounce_start_time_relative: float = 0.0
@export var bounce_end_time_relative: float = 0.3
@export var float_start_time_relative: float = 0.1
@export var float_end_time_relative: float = 1.0
@export var float_distance_px: float = 40.0
@export var fade_start_time_relative: float = 0.5
@export var fade_end_time_relative: float = 1.0

var _number_scene: PackedScene = preload("res://scenes/combat/floating_combat_number.tscn")


func _ready() -> void:
	var world := get_parent()
	for child in world.get_children():
		if child is Character:
			_connect_character(child)
	world.child_entered_tree.connect(_on_child_entered)


func _on_child_entered(node: Node) -> void:
	if node is Character:
		_connect_character(node)


func _connect_character(character: Character) -> void:
	var callback := _on_damage_taken.bind(character)
	if not character.damage_taken.is_connected(callback):
		character.damage_taken.connect(callback)


func _on_damage_taken(amount: int, pos: Vector2, damage_type: String, character: Character) -> void:
	var number := _number_scene.instantiate()
	number.damage_amount = amount
	number.damage_type = damage_type
	number.is_player_damage = character is Player
	number.global_position = pos
	add_child(number)
