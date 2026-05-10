extends Control

const BAR_BASE := preload("res://assets/ui/big_bar_base.png")
const BAR_FILL := preload("res://assets/ui/big_bar_fill.png")
const CENTER_TILES := 3
const BAR_HEIGHT := 64.0
const MARGIN := 16.0
const XP_BAR_HEIGHT := 20.0

var _number_scene: PackedScene = preload("res://scenes/combat/floating_combat_number.tscn")
var _bar: StatusBar


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	_bar = StatusBar.new()
	add_child(_bar)
	_bar.setup(BAR_BASE, BAR_FILL, CENTER_TILES)

	var bar_width := _bar.get_bar_width()
	custom_minimum_size = Vector2(bar_width, BAR_HEIGHT)
	size = Vector2(bar_width, BAR_HEIGHT)
	anchor_left = 0.0
	anchor_top = 1.0
	anchor_right = 0.0
	anchor_bottom = 1.0
	offset_left = MARGIN
	offset_top = -(BAR_HEIGHT + XP_BAR_HEIGHT + MARGIN)
	offset_right = MARGIN + bar_width
	offset_bottom = -(XP_BAR_HEIGHT + MARGIN)


func spawn_floating_number(value: int, is_heal: bool, damage_type: String = "") -> void:
	var number := _number_scene.instantiate()
	number.amount = value
	number.is_heal = is_heal
	number.is_player_damage = not is_heal
	number.damage_type = damage_type
	number.anim_config = {
		"duration": 1.0,
		"bounce_scale": 1.3,
		"bounce_start": 0.0,
		"bounce_end": 0.3,
		"float_start": 0.1,
		"float_end": 1.0,
		"float_distance": 30.0,
		"fade_start": 0.5,
		"fade_end": 1.0,
	}
	number.position = Vector2(size.x / 2.0, -10.0)
	add_child(number)


func update_health(current: float, maximum: float) -> void:
	if _bar == null:
		return
	_bar.update_value(current, maximum)
