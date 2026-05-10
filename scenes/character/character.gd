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
var auto_attack_enabled: bool = true
var base_health_regen_per_second: float = 0.0
var in_combat_health_regen_multiplier: float = 0.0
var moving_hp_regen_multiplier: float = 0.25
var damage_reduction_percent: float = 0.0
var is_reflecting_damage: bool = false
var damage_reflect_percent: float = 0.0

var upgrades: Array = []

var target: Character = null
var _auto_attack_cooldown: float = 0.0
var floating_number_offset_y: float = -40.0
var is_attacking: bool = false
var is_casting: bool = false
var _combat_timer: float = 5.0
var _movement_timer: float = 1.0
var _regen_accumulator: float = 0.0
var _cast_timer: float = 0.0
var _cast_duration: float = 0.0
var _casting_ability: AbilityData = null
var _casting_target: Node = null
var _cast_bar: StatusBar = null
var _cast_bar_offset_y: float = 20.0
var _cast_indicator: Node2D = null

const CAST_BAR_BASE := preload("res://Tiny Swords (Free Pack)/UI Elements/UI Elements/Bars/SmallBar_Base.png")
const CAST_BAR_FILL := preload("res://Tiny Swords (Free Pack)/UI Elements/UI Elements/Bars/SmallBar_Fill.png")


func get_effective_stat(stat_name: String) -> float:
	var value: float = get(stat_name)
	for upgrade in upgrades:
		if upgrade.stat_modifiers.has(stat_name):
			value += upgrade.stat_modifiers[stat_name]
	return value


func add_upgrade(upgrade: UpgradeData) -> void:
	upgrades.append(upgrade)
	if upgrade.stat_modifiers.has("max_health"):
		heal(upgrade.stat_modifiers["max_health"], "upgrade")


func _process(delta: float) -> void:
	_process_auto_attack(delta)
	_process_health_regen(delta)
	_process_casting(delta)


func _process_auto_attack(delta: float) -> void:
	if not auto_attack_enabled:
		return
	if _auto_attack_cooldown > 0.0:
		_auto_attack_cooldown -= delta
	if target == null:
		return
	if not is_instance_valid(target):
		target = null
		return
	var dist := global_position.distance_to(target.global_position)
	if dist <= auto_attack_range_px and _auto_attack_cooldown <= 0.0 and not is_attacking and not is_casting:
		_auto_attack_cooldown = 1.0 / auto_attack_per_second
		var damage := get_effective_stat("base_damage") + get_effective_stat("strength")
		play_attack_animation()
		_apply_delayed_damage(target, damage, auto_attack_delay)


func _apply_delayed_damage(attack_target: Character, damage: float, delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	if is_instance_valid(attack_target) and attack_target.health > 0.0:
		attack_target.take_damage(damage, "auto_attack", self)


func _process_health_regen(delta: float) -> void:
	_combat_timer += delta
	_movement_timer += delta
	if velocity != Vector2.ZERO:
		_movement_timer = 0.0

	if base_health_regen_per_second <= 0.0 or health >= get_effective_stat("max_health"):
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


func take_damage(amount: float, damage_type: String = "auto_attack", attacker: Character = null) -> void:
	_combat_timer = 0.0
	var reduced := amount * (1.0 - damage_reduction_percent / 100.0)
	health -= reduced
	damage_taken.emit(int(reduced), _get_floating_number_position(), damage_type)
	health_changed.emit(-int(reduced), _get_floating_number_position(), damage_type)
	if is_reflecting_damage and damage_type != "reflect" and attacker != null and is_instance_valid(attacker):
		var reflect_amount := reduced * (damage_reflect_percent / 100.0)
		if reflect_amount > 0.0:
			attacker.take_damage(reflect_amount, "reflect")
	if health <= 0.0:
		die()


func heal(amount: float, heal_type: String = "heal") -> void:
	var actual := minf(amount, get_effective_stat("max_health") - health)
	if actual <= 0.0:
		return
	health += actual
	health_changed.emit(int(actual), _get_floating_number_position(), heal_type)


func die() -> void:
	if is_casting:
		cancel_cast()
	died.emit(self)
	queue_free()


func play_attack_animation(_anim_name: StringName = &"attack") -> void:
	pass


func start_cast(ability: AbilityData) -> void:
	if ability == null:
		return

	# Instant abilities skip the cast UI and apply immediately. cast_time = 0
	# would otherwise divide-by-zero in StatusBar.update_value.
	if ability.cast_time <= 0.0:
		ability.apply_effect(self, _casting_target as Player)
		return

	is_casting = true
	_cast_timer = 0.0
	_cast_duration = ability.cast_time
	_casting_ability = ability

	_cast_bar = StatusBar.new()
	add_child(_cast_bar)
	_cast_bar.setup(CAST_BAR_BASE, CAST_BAR_FILL, 1)
	_cast_bar.set_fill_color(Color(1.0, 0.85, 0.0))
	_cast_bar.position.x = -_cast_bar.get_bar_width() / 2.0
	_cast_bar.position.y = _cast_bar_offset_y
	_cast_bar.update_value(0.0, _cast_duration)

	var indicator := ability.make_cast_indicator(self)
	if indicator:
		add_child(indicator)
		_cast_indicator = indicator


func _process_casting(delta: float) -> void:
	if not is_casting:
		return
	_cast_timer += delta
	if _cast_bar:
		_cast_bar.update_value(_cast_timer, _cast_duration)
	if _cast_timer >= _cast_duration:
		var target_valid := _casting_target == null or is_instance_valid(_casting_target)
		if target_valid:
			_casting_ability.apply_effect(self, _casting_target as Player)
		_finish_cast()


func _finish_cast() -> void:
	is_casting = false
	_casting_ability = null
	_casting_target = null
	if _cast_bar:
		_cast_bar.queue_free()
		_cast_bar = null
	if _cast_indicator:
		_cast_indicator.queue_free()
		_cast_indicator = null
	_on_cast_finished()


func cancel_cast() -> void:
	is_casting = false
	_casting_ability = null
	_casting_target = null
	if _cast_bar:
		_cast_bar.queue_free()
		_cast_bar = null
	if _cast_indicator:
		_cast_indicator.queue_free()
		_cast_indicator = null


func _on_cast_finished() -> void:
	pass


func _get_floating_number_position() -> Vector2:
	return global_position + Vector2(0, floating_number_offset_y)
