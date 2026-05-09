extends Control

const SLOT_WIDTH := 128.0
const SLOT_HEIGHT := 128.0
const SLOT_GAP := -20
const MARGIN := 4

const SLOT_VARIANTS := [
	ActionBarSlot.Variant.BLUE,
	ActionBarSlot.Variant.BLUE,
	ActionBarSlot.Variant.RED,
	ActionBarSlot.Variant.RED,
]

var _player: Player = null
var _slots: Array[ActionBarSlot] = []


func setup(player: Player) -> void:
	_player = player
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	for i in range(Player.MAX_ABILITY_SLOTS):
		var slot := ActionBarSlot.new()
		slot.setup(SLOT_VARIANTS[i], SLOT_WIDTH, SLOT_HEIGHT)
		slot.position = Vector2(i * (SLOT_WIDTH + SLOT_GAP), 0)
		add_child(slot)
		_slots.append(slot)

	var total_width := SLOT_WIDTH * Player.MAX_ABILITY_SLOTS + SLOT_GAP * (Player.MAX_ABILITY_SLOTS - 1)
	custom_minimum_size = Vector2(total_width, SLOT_HEIGHT)
	size = Vector2(total_width, SLOT_HEIGHT)
	anchor_left = 1.0
	anchor_top = 1.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = -(total_width + MARGIN)
	offset_top = -(SLOT_HEIGHT + MARGIN)
	offset_right = -MARGIN
	offset_bottom = -MARGIN

	player.ability_cooldown_changed.connect(_on_cooldown_changed)


func _process(_delta: float) -> void:
	if _player == null:
		return
	for i in range(_slots.size()):
		var has_ability := i < _player.abilities.size() and _player.abilities[i] != null
		var on_cooldown := i < _player.ability_cooldowns.size() and _player.ability_cooldowns[i] > 0.0
		var button_held := Input.is_action_pressed("p%d_ability_%d" % [_player.player_index + 1, i + 1])

		_slots[i].set_pressed(on_cooldown or button_held)
		_slots[i].set_desaturated(on_cooldown or not has_ability)
		_slots[i].set_icon(_player.abilities[i].icon if has_ability else null)
		if not on_cooldown:
			_update_slot_label(i)


func _on_cooldown_changed(slot: int, remaining: float, _total: float) -> void:
	if slot >= _slots.size():
		return
	if remaining > 0.0:
		_slots[slot].set_cooldown_text("%.1f" % remaining)
	else:
		_update_slot_label(slot)


func _update_slot_label(slot: int) -> void:
		_slots[slot].set_cooldown_text("")
