class_name CpuController
extends Node

enum State { COMBAT, RECOVERING, SEEKING, SELECTING_TARGET, SELECTING_UPGRADE }

const ACTION_INTERVAL := 1.0
const UI_STEP_DELAY := 0.15
const HEALTH_THRESHOLD_LOW := 0.5
const HEALTH_THRESHOLD_RECOVER := 0.8
const KITE_RUN_DURATION := 1.0
const KITE_STAND_DURATION := 1.0

var player: Player = null
var player_index: int = 0
var _state: State = State.SEEKING
var _action_cooldown: float = 0.0
var _desired_target_ui_index: int = 0
var _ui_step: int = 0
var _ui_delay: float = 0.0
var _recovering: bool = false
var _kite_timer: float = 0.0
var _kite_running: bool = true


func setup(p: Player, index: int) -> void:
	player = p
	player_index = index
	set_process_priority(-1)


func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player) or player.health <= 0.0:
		InputManager.set_virtual_movement(player_index, Vector2.ZERO)
		return

	_action_cooldown -= delta

	if _check_upgrade_pending():
		return

	if _state == State.SELECTING_TARGET:
		_process_selecting_target(delta)
		return
	if _state == State.SELECTING_UPGRADE:
		_process_selecting_upgrade(delta)
		return

	var has_target := player.target != null and is_instance_valid(player.target)
	if has_target:
		_recovering = false
		_state = State.COMBAT
	else:
		_update_out_of_combat_state()

	match _state:
		State.COMBAT:
			_process_combat(delta)
		State.RECOVERING:
			_process_recovering()
		State.SEEKING:
			_process_seeking()


func _check_upgrade_pending() -> bool:
	if player.pending_upgrade_count > 0 and not player.is_selecting_upgrade and _state != State.SELECTING_UPGRADE:
		InputManager.set_virtual_movement(player_index, Vector2.ZERO)
		InputManager.press_virtual_action(player_index, "open_upgrades")
		_state = State.SELECTING_UPGRADE
		_ui_delay = UI_STEP_DELAY
		return true
	return false


func _update_out_of_combat_state() -> void:
	var health_ratio := player.health / player.get_effective_stat("max_health")
	if health_ratio < HEALTH_THRESHOLD_LOW:
		_recovering = true
	elif health_ratio >= HEALTH_THRESHOLD_RECOVER:
		_recovering = false
	if _recovering:
		_state = State.RECOVERING
	else:
		_state = State.SEEKING


func _process_combat(delta: float) -> void:
	if player.target == null or not is_instance_valid(player.target):
		InputManager.set_virtual_movement(player_index, Vector2.ZERO)
		return

	if _action_cooldown <= 0.0 and not player.is_casting:
		_try_whirlwind()

	var health_ratio := player.health / player.get_effective_stat("max_health")
	if health_ratio < HEALTH_THRESHOLD_LOW:
		if _action_cooldown <= 0.0 and not player.is_casting:
			_try_guard()
		_process_kiting(delta)
	else:
		InputManager.set_virtual_movement(player_index, Vector2.ZERO)
		_kite_timer = 0.0
		_kite_running = true


func _process_kiting(delta: float) -> void:
	_kite_timer += delta
	if _kite_running:
		if _kite_timer >= KITE_RUN_DURATION:
			_kite_timer = 0.0
			_kite_running = false
		else:
			var away := player.global_position - player.target.global_position
			if away.length() > 0.0:
				InputManager.set_virtual_movement(player_index, away.normalized())
			else:
				InputManager.set_virtual_movement(player_index, Vector2.RIGHT)
	else:
		if _kite_timer >= KITE_STAND_DURATION:
			_kite_timer = 0.0
			_kite_running = true
		else:
			InputManager.set_virtual_movement(player_index, Vector2.ZERO)


func _process_recovering() -> void:
	InputManager.set_virtual_movement(player_index, Vector2.ZERO)


func _process_seeking() -> void:
	if _action_cooldown <= 0.0 and not player.is_casting:
		if _try_card_ability():
			return

	if _has_card_abilities():
		InputManager.set_virtual_movement(player_index, Vector2.ZERO)
		return

	var enemy := _find_closest_enemy()
	if enemy == null:
		InputManager.set_virtual_movement(player_index, Vector2.ZERO)
		return

	var to_enemy := enemy.global_position - player.global_position
	InputManager.set_virtual_movement(player_index, to_enemy.normalized())


func _try_whirlwind() -> bool:
	if 0 >= player.abilities.size() or player.abilities[0] == null:
		return false
	if player.ability_cooldowns[0] > 0.0:
		return false
	InputManager.press_virtual_action(player_index, "ability_1")
	_action_cooldown = ACTION_INTERVAL
	return true


func _try_guard() -> bool:
	if player.is_guarding:
		return false
	if 1 >= player.abilities.size() or player.abilities[1] == null:
		return false
	if player.ability_cooldowns[1] > 0.0:
		return false
	InputManager.press_virtual_action(player_index, "ability_2")
	_action_cooldown = ACTION_INTERVAL
	return true


func _try_card_ability() -> bool:
	for slot in [2, 3]:
		if slot >= player.abilities.size() or player.abilities[slot] == null:
			continue
		if player.ability_cooldowns[slot] > 0.0:
			continue
		var ability := player.abilities[slot]
		if ability.is_card and ability.needs_player_target():
			_initiate_card_ability(slot)
			return true
		else:
			InputManager.press_virtual_action(player_index, "ability_%d" % (slot + 1))
			_action_cooldown = ACTION_INTERVAL
			return true
	return false


func _has_card_abilities() -> bool:
	for slot in [2, 3]:
		if slot < player.abilities.size() and player.abilities[slot] != null:
			return true
	return false


func _initiate_card_ability(slot: int) -> void:
	if GameState.player_count == 2:
		InputManager.press_virtual_action(player_index, "ability_%d" % (slot + 1))
		_action_cooldown = ACTION_INTERVAL
		return

	_desired_target_ui_index = _pick_weakest_opponent_ui_index()
	_ui_step = 0
	_ui_delay = UI_STEP_DELAY
	_state = State.SELECTING_TARGET
	InputManager.press_virtual_action(player_index, "ability_%d" % (slot + 1))


func _pick_weakest_opponent_ui_index() -> int:
	var target_indices: Array[int] = []
	for i in range(GameState.players.size()):
		var p := GameState.players[i]
		if p != null and is_instance_valid(p) and p is Player and i != player_index:
			target_indices.append(i)

	var best_ui_idx := 0
	var lowest_health := INF
	for ui_idx in range(target_indices.size()):
		var p := GameState.players[target_indices[ui_idx]] as Player
		if p != null and is_instance_valid(p) and p.health < lowest_health:
			lowest_health = p.health
			best_ui_idx = ui_idx
	return best_ui_idx


func _find_closest_enemy() -> Character:
	var world := player.get_parent() as Node2D
	if world == null:
		return null
	var closest: Character = null
	var closest_dist := INF
	for child in world.get_children():
		if child is Enemy and is_instance_valid(child) and child.health > 0.0:
			var dist := player.global_position.distance_to(child.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest = child
	return closest


func _process_selecting_target(delta: float) -> void:
	if not player.is_selecting_target:
		_state = State.COMBAT
		_action_cooldown = ACTION_INTERVAL
		return

	_ui_delay -= delta
	if _ui_delay > 0.0:
		return

	if _ui_step < _desired_target_ui_index:
		InputManager.press_virtual_action(player_index, "move_down")
		_ui_step += 1
		_ui_delay = UI_STEP_DELAY
	else:
		InputManager.press_virtual_action(player_index, "switch_target")
		_action_cooldown = ACTION_INTERVAL
		_state = State.COMBAT


func _process_selecting_upgrade(delta: float) -> void:
	if not player.is_selecting_upgrade:
		_state = State.COMBAT
		return

	_ui_delay -= delta
	if _ui_delay > 0.0:
		return

	InputManager.press_virtual_action(player_index, "switch_target")
	_ui_delay = UI_STEP_DELAY
