class_name OtherPlayerCastingDisplayController
extends VBoxContainer

const MARGIN := 16.0

var _player_index: int = -1
var _active_rows: Dictionary = {}


func setup(player_index: int) -> void:
	_player_index = player_index
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 4)
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 0.0
	anchor_bottom = 0.0
	offset_left = MARGIN
	offset_top = MARGIN
	GameState.targeting_cast_started.connect(_on_cast_started)
	GameState.targeting_cast_ended.connect(_on_cast_ended)


func _process(_delta: float) -> void:
	for key in _active_rows.keys():
		var caster_idx: int = key
		if caster_idx >= GameState.players.size():
			_remove_row(caster_idx)
			continue
		var p := GameState.players[caster_idx]
		if p == null or not is_instance_valid(p):
			_remove_row(caster_idx)


func _on_cast_started(caster_index: int, target_index: int, ability: AbilityData) -> void:
	if target_index != _player_index:
		return
	_remove_row(caster_index)
	var row := OtherPlayerCastingRowItem.new()
	add_child(row)
	row.setup(ability, caster_index)
	_active_rows[caster_index] = row


func _on_cast_ended(caster_index: int, target_index: int) -> void:
	if target_index != _player_index:
		return
	_remove_row(caster_index)


func _remove_row(caster_idx: int) -> void:
	if not _active_rows.has(caster_idx):
		return
	var row: OtherPlayerCastingRowItem = _active_rows[caster_idx]
	row.queue_free()
	_active_rows.erase(caster_idx)
