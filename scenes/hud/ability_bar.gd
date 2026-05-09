extends Control

const SLOT_SIZE := 48.0
const SLOT_GAP := 6.0
const MARGIN := 16.0
const BG_COLOR := Color(0.15, 0.15, 0.2, 0.8)
const READY_COLOR := Color(0.3, 0.6, 0.3, 0.9)
const COOLDOWN_COLOR := Color(0.1, 0.1, 0.1, 0.7)

var _slots: Array[Control] = []
var _cooldown_overlays: Array[ColorRect] = []
var _cooldown_labels: Array[Label] = []
var _key_labels: Array[Label] = []
var _player: Player = null


func setup(player: Player) -> void:
	_player = player
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	for i in range(Player.MAX_ABILITY_SLOTS):
		var slot := _create_slot(i)
		add_child(slot)
		_slots.append(slot)

	var total_width := SLOT_SIZE * Player.MAX_ABILITY_SLOTS + SLOT_GAP * (Player.MAX_ABILITY_SLOTS - 1)
	custom_minimum_size = Vector2(total_width, SLOT_SIZE)
	size = Vector2(total_width, SLOT_SIZE)
	anchor_left = 1.0
	anchor_top = 1.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = -(total_width + MARGIN)
	offset_top = -(SLOT_SIZE + MARGIN)
	offset_right = -MARGIN
	offset_bottom = -MARGIN

	player.ability_cooldown_changed.connect(_on_cooldown_changed)
	_update_slot_visibility()


func _create_slot(index: int) -> Control:
	var slot := Control.new()
	slot.position = Vector2(index * (SLOT_SIZE + SLOT_GAP), 0)
	slot.size = Vector2(SLOT_SIZE, SLOT_SIZE)
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bg := ColorRect.new()
	bg.size = Vector2(SLOT_SIZE, SLOT_SIZE)
	bg.color = READY_COLOR
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(bg)

	var overlay := ColorRect.new()
	overlay.size = Vector2(SLOT_SIZE, 0)
	overlay.position = Vector2(0, 0)
	overlay.color = COOLDOWN_COLOR
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(overlay)
	_cooldown_overlays.append(overlay)

	var cd_label := Label.new()
	cd_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cd_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cd_label.size = Vector2(SLOT_SIZE, SLOT_SIZE)
	cd_label.add_theme_font_size_override("font_size", 16)
	cd_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(cd_label)
	_cooldown_labels.append(cd_label)

	var key_label := Label.new()
	key_label.text = str(index + 1)
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	key_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	key_label.size = Vector2(SLOT_SIZE - 4, SLOT_SIZE - 2)
	key_label.position = Vector2(2, 1)
	key_label.add_theme_font_size_override("font_size", 10)
	key_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	key_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(key_label)
	_key_labels.append(key_label)

	return slot


func _on_cooldown_changed(slot: int, remaining: float, total: float) -> void:
	if slot >= _cooldown_overlays.size():
		return
	var ratio := remaining / total if total > 0.0 else 0.0
	_cooldown_overlays[slot].size.y = SLOT_SIZE * ratio
	if remaining > 0.0:
		_cooldown_labels[slot].text = str(ceili(remaining))
	else:
		_cooldown_labels[slot].text = ""


func _update_slot_visibility() -> void:
	if _player == null:
		return
	for i in range(_slots.size()):
		_slots[i].visible = i < _player.abilities.size() and _player.abilities[i] != null
