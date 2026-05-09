extends CharacterBody2D
class_name Character

signal damage_taken(amount: int, world_pos: Vector2, damage_type: String)
signal died(character: Character)

var health: float = 100.0
var max_health: float = 100.0
var base_damage: float = 10.0
var strength: float = 0.0
var auto_attack_per_second: float = 1.0
var auto_attack_delay: float = 0.2
var movement_speed: float = 200.0
var target_range_px: float = 200.0
var auto_attack_range_px: float = 100.0

var target: Character = null
var _auto_attack_cooldown: float = 0.0
var floating_number_offset_y: float = -40.0
var is_attacking: bool = false


func _process(delta: float) -> void:
	_process_auto_attack(delta)


func _process_auto_attack(delta: float) -> void:
	if _auto_attack_cooldown > 0.0:
		_auto_attack_cooldown -= delta
	if target == null:
		return
	if not is_instance_valid(target):
		target = null
		return
	var dist := global_position.distance_to(target.global_position)
	if dist <= auto_attack_range_px and _auto_attack_cooldown <= 0.0 and not is_attacking:
		_auto_attack_cooldown = 1.0 / auto_attack_per_second
		var damage := base_damage + strength
		play_attack_animation()
		_apply_delayed_damage(target, damage, auto_attack_delay)


func _apply_delayed_damage(attack_target: Character, damage: float, delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	if is_instance_valid(attack_target) and attack_target.health > 0.0:
		attack_target.take_damage(damage)


func take_damage(amount: float, damage_type: String = "auto_attack") -> void:
	health -= amount
	damage_taken.emit(int(amount), _get_floating_number_position(), damage_type)
	if health <= 0.0:
		die()


func die() -> void:
	died.emit(self)
	queue_free()


func play_attack_animation() -> void:
	pass


func _get_floating_number_position() -> Vector2:
	return global_position + Vector2(0, floating_number_offset_y)
