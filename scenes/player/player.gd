extends Character
class_name Player

const FRAME_SIZE := 192
const DEFAULT_DATA: PlayerData = preload("res://scenes/player/default_player.tres")
const DEFAULT_WHIRLWIND: AbilityData = preload("res://scenes/ability/types/whirlwind.tres")
const DEFAULT_GUARD: AbilityData = preload("res://scenes/ability/types/guard.tres")
const LEVEL_DATA: LevelData = preload("res://scenes/player/level_data.tres")
const MAX_ABILITY_SLOTS := 4
const UPGRADE_POOL: Array[UpgradeData] = [
	preload("res://scenes/upgrade/types/max_health.tres"),
	preload("res://scenes/upgrade/types/strength.tres"),
	preload("res://scenes/upgrade/types/health_regen.tres"),
]

signal ability_used(slot_index: int)
signal ability_cooldown_changed(slot_index: int, remaining: float, total: float)
signal experience_changed(current_xp: float, xp_required: float)
signal experience_gained(amount: int, world_pos: Vector2)
signal leveled_up(new_level: int)
signal upgrade_selection_requested(options: Array)
signal upgrade_selection_completed()

var sprite: AnimatedSprite2D
var player_index: int = 0
var player_color: Color = Color.WHITE
var potential_targets: Array[Character] = []
var _prev_target_list_empty: bool = true
var abilities: Array[AbilityData] = []
var ability_cooldowns: Array[float] = []
var experience: float = 0.0
var level: int = 1
var _casting_slot: int = -1
var is_selecting_upgrade: bool = false
var pending_upgrade_count: int = 0
var god_mode: bool = false  # debug panel toggles this; bypasses take_damage entirely
var is_guarding: bool = false
var _guard_timer: float = 0.0
var _guard_duration: float = 0.0


func setup(index: int, color: Color) -> void:
	_apply_stats(DEFAULT_DATA)
	player_index = index
	player_color = color
	sprite = $AnimatedSprite2D
	sprite.sprite_frames = _build_sprite_frames()
	sprite.play("idle")
	equip_ability(DEFAULT_WHIRLWIND, 0)
	equip_ability(DEFAULT_GUARD, 1)


func _process(delta: float) -> void:
	super(delta)
	if is_guarding:
		_guard_timer += delta
		if _guard_timer >= _guard_duration:
			_end_guard()
	if InputManager.is_action_just_pressed(player_index, "open_upgrades"):
		_open_upgrade_menu()
	if is_selecting_upgrade:
		return
	_update_target_list()
	_handle_auto_target()
	if InputManager.is_action_just_pressed(player_index, "switch_target"):
		_cycle_target()
	_tick_ability_cooldowns(delta)
	for i in range(abilities.size()):
		if abilities[i] == null:
			continue
		if InputManager.is_action_just_pressed(player_index, "ability_%d" % (i + 1)):
			_try_use_ability(i)


func _physics_process(_delta: float) -> void:
	if is_casting or is_selecting_upgrade:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var direction := InputManager.get_movement_vector(player_index)
	var speed := movement_speed
	if is_guarding:
		speed *= 0.5
	velocity = direction * speed
	move_and_slide()
	GameState.update_player_position(player_index, global_position)

	if is_attacking:
		return
	if is_guarding:
		if sprite.animation != &"guard":
			sprite.play("guard")
		if velocity.x < 0:
			sprite.flip_h = true
		elif velocity.x > 0:
			sprite.flip_h = false
	elif velocity != Vector2.ZERO:
		if sprite.animation != &"run":
			sprite.play("run")
		if velocity.x < 0:
			sprite.flip_h = true
		elif velocity.x > 0:
			sprite.flip_h = false
	else:
		if sprite.animation != &"idle":
			sprite.play("idle")


func _build_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	var n := player_index + 1
	var base_path := "res://assets/players/player%d/player_%d_" % [n, n]

	_add_animation(frames, "idle", load(base_path + "idle.png"), 8)
	_add_animation(frames, "run", load(base_path + "run.png"), 6)
	_add_animation(frames, "attack", load(base_path + "attack_1.png"), 4, false)
	_add_animation(frames, "attack_2", load(base_path + "attack_2.png"), 4, false)
	_add_animation(frames, "guard", load(base_path + "guard.png"), 6)

	frames.remove_animation("default")
	return frames


func _add_animation(frames: SpriteFrames, anim_name: String, sheet: Texture2D, frame_count: int, looping: bool = true) -> void:
	frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, 10)
	frames.set_animation_loop(anim_name, looping)
	for i in range(frame_count):
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(i * FRAME_SIZE, 0, FRAME_SIZE, FRAME_SIZE)
		frames.add_frame(anim_name, atlas)


func play_attack_animation(anim_name: StringName = &"attack") -> void:
	is_attacking = true
	sprite.play(anim_name)
	await sprite.animation_finished
	is_attacking = false


func _update_target_list() -> void:
	var world := get_parent() as Node2D
	if world == null:
		return
	var new_targets: Array[Character] = []
	for child in world.get_children():
		if child is Enemy and is_instance_valid(child):
			var dist := global_position.distance_to(child.global_position)
			if dist <= target_range_px:
				new_targets.append(child)
	potential_targets = new_targets


func _handle_auto_target() -> void:
	var is_empty := potential_targets.is_empty()
	if _prev_target_list_empty and not is_empty:
		target = potential_targets[0]
	elif not _prev_target_list_empty and is_empty:
		target = null
	_prev_target_list_empty = is_empty
	if target != null and not potential_targets.has(target):
		if potential_targets.is_empty():
			target = null
		else:
			target = potential_targets[0]
	if target == null and not potential_targets.is_empty():
		target = potential_targets[0]


func _cycle_target() -> void:
	if potential_targets.is_empty():
		return
	if target == null or not potential_targets.has(target):
		target = potential_targets[0]
		return
	var current_index := potential_targets.find(target)
	var next_index := (current_index + 1) % potential_targets.size()
	target = potential_targets[next_index]


func _apply_stats(data: PlayerData) -> void:
	health = data.health
	max_health = data.max_health
	base_damage = data.base_damage
	strength = data.strength
	auto_attack_per_second = data.auto_attack_per_second
	auto_attack_delay = data.auto_attack_delay
	movement_speed = data.movement_speed
	target_range_px = data.target_range_px
	auto_attack_range_px = data.auto_attack_range_px
	base_health_regen_per_second = data.base_health_regen_per_second
	in_combat_health_regen_multiplier = data.in_combat_health_regen_multiplier
	moving_hp_regen_multiplier = data.moving_hp_regen_multiplier
	experience = data.experience
	level = data.level


func start_guard(duration: float) -> void:
	is_guarding = true
	_guard_timer = 0.0
	_guard_duration = duration
	damage_reduction_percent = 50.0


func _end_guard() -> void:
	is_guarding = false
	_guard_timer = 0.0
	_guard_duration = 0.0
	damage_reduction_percent = 0.0


func equip_ability(ability: AbilityData, slot: int) -> void:
	while abilities.size() <= slot:
		abilities.append(null)
		ability_cooldowns.append(0.0)
	abilities[slot] = ability
	ability_cooldowns[slot] = 0.0


func _try_use_ability(slot: int) -> void:
	if slot >= abilities.size() or abilities[slot] == null:
		return
	if ability_cooldowns[slot] > 0.0:
		return
	if is_casting:
		return
	var ability := abilities[slot]
	if ability.cast_time > 0.0:
		_casting_slot = slot
		start_cast(ability)
		ability_used.emit(slot)
	elif ability.execute(self):
		ability_cooldowns[slot] = ability.cooldown
		ability_used.emit(slot)
		if ability.animation != &"":
			play_attack_animation(ability.animation)


func _tick_ability_cooldowns(delta: float) -> void:
	for i in range(ability_cooldowns.size()):
		if abilities[i] == null:
			continue
		if ability_cooldowns[i] > 0.0:
			ability_cooldowns[i] = maxf(ability_cooldowns[i] - delta, 0.0)
			ability_cooldown_changed.emit(i, ability_cooldowns[i], abilities[i].cooldown)


func gain_experience(amount: float) -> void:
	if level >= LEVEL_DATA.max_level:
		return
	experience += amount
	experience_gained.emit(int(amount), _get_floating_number_position())
	while level < LEVEL_DATA.max_level and experience >= LEVEL_DATA.get_xp_required(level):
		experience -= LEVEL_DATA.get_xp_required(level)
		level += 1
		leveled_up.emit(level)
		pending_upgrade_count += 1
	var xp_req := LEVEL_DATA.get_xp_required(level)
	if xp_req > 0.0:
		experience_changed.emit(experience, xp_req)
	else:
		experience_changed.emit(0.0, 1.0)


func _open_upgrade_menu() -> void:
	if pending_upgrade_count <= 0 or is_selecting_upgrade:
		return
	is_selecting_upgrade = true
	var options := UpgradeData.pick_weighted(UPGRADE_POOL, 3)
	upgrade_selection_requested.emit(options)


func apply_selected_upgrade(upgrade: UpgradeData) -> void:
	add_upgrade(upgrade)
	pending_upgrade_count -= 1
	is_selecting_upgrade = false
	upgrade_selection_completed.emit()


func try_grant_card(ability: AbilityData) -> bool:
	for slot in [2, 3]:
		if slot >= abilities.size() or abilities[slot] == null:
			equip_ability(ability, slot)
			return true
	return false


func _on_cast_finished() -> void:
	var slot := _casting_slot
	_casting_slot = -1
	if slot < 0 or slot >= abilities.size() or abilities[slot] == null:
		return
	var ability := abilities[slot]
	if ability.is_card:
		ability.num_charges -= 1
		if ability.num_charges <= 0:
			abilities[slot] = null


func take_damage(amount: float, damage_type: String = "auto_attack") -> void:
	if god_mode:
		return
	super.take_damage(amount, damage_type)


func die() -> void:
	var world := get_parent()
	if world and world.has_method("on_player_died"):
		world.on_player_died()
	super()
