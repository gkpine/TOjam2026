extends Character
class_name Player

const FRAME_SIZE := 192
const DEFAULT_DATA: PlayerData = preload("res://scenes/player/default_player.tres")
const DEFAULT_WHIRLWIND: AbilityData = preload("res://scenes/ability/types/whirlwind.tres")
const MAX_ABILITY_SLOTS := 4

signal ability_used(slot_index: int)
signal ability_cooldown_changed(slot_index: int, remaining: float, total: float)

var sprite: AnimatedSprite2D
var player_index: int = 0
var player_color: Color = Color.WHITE
var potential_targets: Array[Character] = []
var _prev_target_list_empty: bool = true
var abilities: Array[AbilityData] = []
var ability_cooldowns: Array[float] = []


func setup(index: int, color: Color) -> void:
	_apply_stats(DEFAULT_DATA)
	player_index = index
	player_color = color
	sprite = $AnimatedSprite2D
	sprite.sprite_frames = _build_sprite_frames()
	sprite.play("idle")
	equip_ability(DEFAULT_WHIRLWIND, 0)


func _process(delta: float) -> void:
	super(delta)
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
	var direction := InputManager.get_movement_vector(player_index)
	velocity = direction * movement_speed
	move_and_slide()
	GameState.update_player_position(player_index, global_position)

	if is_attacking:
		return
	if velocity != Vector2.ZERO:
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
	if abilities[slot].execute(self):
		ability_cooldowns[slot] = abilities[slot].cooldown
		ability_used.emit(slot)
		if abilities[slot].animation != &"":
			play_attack_animation(abilities[slot].animation)


func _tick_ability_cooldowns(delta: float) -> void:
	for i in range(ability_cooldowns.size()):
		if ability_cooldowns[i] > 0.0:
			ability_cooldowns[i] = maxf(ability_cooldowns[i] - delta, 0.0)
			ability_cooldown_changed.emit(i, ability_cooldowns[i], abilities[i].cooldown)


func die() -> void:
	var world := get_parent()
	if world and world.has_method("on_player_died"):
		world.on_player_died()
	super()
