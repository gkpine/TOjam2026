class_name UpgradeOptionsController
extends Control

const OPTION_GAP := 10.0
const OVERLAY_COLOR := Color(0.0, 0.0, 0.0, 0.55)

var _overlay: ColorRect = null
var _options: Array[UpgradeOption] = []
var _selected_index: int = 0
var _player_index: int = 0
var _player: Player = null
var _upgrade_data: Array = []


func setup(player: Player) -> void:
	_player = player
	_player_index = player.player_index
	var vp_size := get_viewport_rect().size
	size = vp_size

	_overlay = ColorRect.new()
	_overlay.size = vp_size
	_overlay.color = OVERLAY_COLOR
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)

	player.upgrade_selection_requested.connect(_on_selection_requested)
	player.upgrade_selection_completed.connect(_on_selection_completed)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _on_selection_requested(options: Array) -> void:
	_clear_options()
	_upgrade_data = options

	for i in range(options.size()):
		var option := UpgradeOption.new()
		option.setup(options[i])
		add_child(option)
		_options.append(option)

	var card_size := _options[0].size
	var n := _options.size()
	var vp_size := get_viewport_rect().size
	var total_width := n * card_size.x + (n - 1) * OPTION_GAP
	var x_start := (vp_size.x - total_width) / 2.0
	var y_pos := (vp_size.y - card_size.y) / 2.0

	var x_offset := x_start
	for option in _options:
		option.position = Vector2(x_offset, y_pos)
		x_offset += card_size.x + OPTION_GAP

	_selected_index = 0
	_update_selection()
	visible = true


func _on_selection_completed() -> void:
	_clear_options()
	visible = false


func _process(_delta: float) -> void:
	if not visible or _player == null:
		return
	if InputManager.is_action_just_pressed(_player_index, "move_left"):
		_selected_index = maxi(_selected_index - 1, 0)
		_update_selection()
	elif InputManager.is_action_just_pressed(_player_index, "move_right"):
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
