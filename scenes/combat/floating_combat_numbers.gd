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
	var damage_callback := _on_damage_taken.bind(character)
	if not character.damage_taken.is_connected(damage_callback):
		character.damage_taken.connect(damage_callback)
	var health_callback := _on_health_changed.bind(character)
	if not character.health_changed.is_connected(health_callback):
		character.health_changed.connect(health_callback)


func _on_damage_taken(amount: int, pos: Vector2, damage_type: String, character: Character) -> void:
	if character is Player:
		return
	var number := _number_scene.instantiate()
	number.amount = amount
	number.damage_type = damage_type
	number.anim_config = _build_anim_config()
	number.global_position = pos
	add_child(number)


func _on_health_changed(amount: int, pos: Vector2, _change_type: String, character: Character) -> void:
	if character is Player:
		return
	if amount <= 0:
		return
	var number := _number_scene.instantiate()
	number.amount = amount
	number.is_heal = true
	number.anim_config = _build_anim_config()
	number.global_position = pos
	add_child(number)


func _build_anim_config() -> Dictionary:
	return {
		"duration": animation_duration_seconds,
		"bounce_scale": bounce_scale,
		"bounce_start": bounce_start_time_relative,
		"bounce_end": bounce_end_time_relative,
		"float_start": float_start_time_relative,
		"float_end": float_end_time_relative,
		"float_distance": float_distance_px,
		"fade_start": fade_start_time_relative,
		"fade_end": fade_end_time_relative,
	}
