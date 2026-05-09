extends CharacterBody2D
class_name Character

signal damage_taken(amount: int, world_pos: Vector2, damage_type: String)
signal health_changed(amount: int, world_pos: Vector2, change_type: String)
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
var base_health_regen_per_second: float = 0.0
var in_combat_health_regen_multiplier: float = 0.0
var moving_hp_regen_multiplier: float = 0.25

var target: Character = null
var _auto_attack_cooldown: float = 0.0
var floating_number_offset_y: float = -40.0
var is_attacking: bool = false
var _combat_timer: float = 5.0
var _movement_timer: float = 1.0
var _regen_accumulator: float = 0.0


func _process(delta: float) -> void:
	_process_auto_attack(delta)
	_process_health_regen(delta)


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


func _process_health_regen(delta: float) -> void:
	_combat_timer += delta
	_movement_timer += delta
	if velocity != Vector2.ZERO:
		_movement_timer = 0.0

	if base_health_regen_per_second <= 0.0 or health >= max_health:
		_regen_accumulator = 0.0
		return

	var effective_regen := base_health_regen_per_second
	if _combat_timer < 5.0:
		effective_regen *= in_combat_health_regen_multiplier
	if _movement_timer < 0.5:
		effective_regen *= moving_hp_regen_multiplier

	if effective_regen <= 0.0:
		_regen_accumulator = 0.0
		return

	_regen_accumulator += delta
	if _regen_accumulator >= 1.0:
		heal(effective_regen * _regen_accumulator, "regen")
		_regen_accumulator = 0.0


func take_damage(amount: float, damage_type: String = "auto_attack") -> void:
	_combat_timer = 0.0
	health -= amount
	damage_taken.emit(int(amount), _get_floating_number_position(), damage_type)
	health_changed.emit(-int(amount), _get_floating_number_position(), damage_type)
	if health <= 0.0:
		die()


func heal(amount: float, heal_type: String = "heal") -> void:
	var actual := minf(amount, max_health - health)
	if actual <= 0.0:
		return
	health += actual
	health_changed.emit(int(actual), _get_floating_number_position(), heal_type)


func die() -> void:
	died.emit(self)
	queue_free()


func play_attack_animation(_anim_name: StringName = &"attack") -> void:
	pass


func _get_floating_number_position() -> Vector2:
	return global_position + Vector2(0, floating_number_offset_y)
