class_name PlayerSelectController
extends Control

const OPTION_GAP := 8.0
const OPTION_SIZE := Vector2(96, 96)

const SLOT_WIDTH := 128.0
const SLOT_GAP := -20.0
const BAR_MARGIN := 4.0
const BAR_SLOT_COUNT := 4
const COLUMN_GAP_ABOVE_BAR := 8.0

var _options: Array[PlayerSelectOption] = []
var _selected_index: int = 0
var _player: Player = null
var _player_index: int = 0
var _pending_slot: int = -1
var _target_indices: Array[int] = []
var _skip_input_frame: bool = false


func setup(player: Player) -> void:
	_player = player
	_player_index = player.player_index
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	player.target_selection_requested.connect(_on_selection_requested)


func _on_selection_requested(slot: int) -> void:
	_clear_options()
	_target_indices.clear()

	for i in range(GameState.players.size()):
		var p := GameState.players[i]
		if p != null and is_instance_valid(p) and p is Player and i != _player_index:
			_target_indices.append(i)

	if _target_indices.is_empty():
		return

	if _target_indices.size() == 1:
		var target := GameState.players[_target_indices[0]] as Player
		if target != null and is_instance_valid(target):
			_player._use_card_ability_on_target(slot, target)
		return

	_pending_slot = slot
	_player.is_selecting_target = true

	for idx in _target_indices:
		var option := PlayerSelectOption.new()
		option.setup(idx)
		add_child(option)
		_options.append(option)

	_position_options()
	_selected_index = 0
	_update_selection()
	_skip_input_frame = true
	visible = true


func _position_options() -> void:
	var vp_size := get_viewport_rect().size
	var total_bar_width := SLOT_WIDTH * BAR_SLOT_COUNT + SLOT_GAP * (BAR_SLOT_COUNT - 1)
	var bar_left := vp_size.x - total_bar_width - BAR_MARGIN
	var slot_center_x := bar_left + _pending_slot * (SLOT_WIDTH + SLOT_GAP) + SLOT_WIDTH / 2.0
	var column_bottom := vp_size.y - SLOT_WIDTH - BAR_MARGIN - COLUMN_GAP_ABOVE_BAR

	var n := _options.size()
	var total_height := n * OPTION_SIZE.y + (n - 1) * OPTION_GAP
	var y_start := column_bottom - total_height

	for i in range(n):
		_options[i].position = Vector2(
			slot_center_x - OPTION_SIZE.x / 2.0,
			y_start + i * (OPTION_SIZE.y + OPTION_GAP)
		)


func _process(_delta: float) -> void:
	if not visible or _player == null:
		return
	if _skip_input_frame:
		_skip_input_frame = false
		return

	if InputManager.is_action_just_pressed(_player_index, "ability_%d" % (_pending_slot + 1)):
		_cancel()
		return

	if InputManager.is_action_just_pressed(_player_index, "move_up"):
		_selected_index = maxi(_selected_index - 1, 0)
		_update_selection()
	elif InputManager.is_action_just_pressed(_player_index, "move_down"):
		_selected_index = mini(_selected_index + 1, _options.size() - 1)
		_update_selection()

	if InputManager.is_action_just_pressed(_player_index, "switch_target"):
		_confirm_selection()


func _update_selection() -> void:
	for i in range(_options.size()):
		_options[i].set_selected(i == _selected_index)


func _confirm_selection() -> void:
	if _selected_index < 0 or _selected_index >= _target_indices.size():
		return
	var target_index := _target_indices[_selected_index]
	var target_player := GameState.players[target_index] as Player
	if target_player == null or not is_instance_valid(target_player):
		_cancel()
		return
	var slot := _pending_slot
	_close()
	_player._use_card_ability_on_target(slot, target_player)


func _cancel() -> void:
	_close()


func _close() -> void:
	_player.is_selecting_target = false
	_clear_options()
	_pending_slot = -1
	visible = false


func _clear_options() -> void:
	for option in _options:
		option.queue_free()
	_options.clear()
	_target_indices.clear()
