class_name UpgradeOptionsController
extends Control

const OPTION_GAP := -20.0
const LEFT_MARGIN := 16.0
const TOP_MARGIN := 16.0

var _options: Array[AbilityOption] = []
var _selected_index: int = 0
var _player_index: int = 0
var _player: Player = null
var _upgrade_data: Array[UpgradeData] = []


func setup(player: Player) -> void:
	_player = player
	_player_index = player.player_index
	player.upgrade_selection_requested.connect(_on_selection_requested)
	player.upgrade_selection_completed.connect(_on_selection_completed)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _on_selection_requested(options: Array[UpgradeData]) -> void:
	_upgrade_data = options
	_clear_options()

	for i in range(options.size()):
		var option := AbilityOption.new()
		option.setup(options[i])
		option.position = Vector2(LEFT_MARGIN, TOP_MARGIN + i * (option.size.y + OPTION_GAP))
		add_child(option)
		_options.append(option)

	_selected_index = 0
	_update_selection()
	visible = true


func _on_selection_completed() -> void:
	_clear_options()
	visible = false


func _process(_delta: float) -> void:
	if not visible or _player == null:
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
	if _selected_index < 0 or _selected_index >= _upgrade_data.size():
		return
	_player.apply_selected_upgrade(_upgrade_data[_selected_index])


func _clear_options() -> void:
	for option in _options:
		option.queue_free()
	_options.clear()
	_upgrade_data.clear()
