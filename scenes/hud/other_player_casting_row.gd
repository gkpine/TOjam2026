class_name OtherPlayerCastingRowItem
extends HBoxContainer

const BAR_BASE := preload("res://Tiny Swords (Free Pack)/UI Elements/UI Elements/Bars/BigBar_Base.png")
const BAR_FILL := preload("res://Tiny Swords (Free Pack)/UI Elements/UI Elements/Bars/BigBar_Fill.png")
const ICON_SIZE := 64.0

var caster_index: int = -1
var _cast_timer: float = 0.0
var _cast_duration: float = 0.0
var _bar: StatusBar


func setup(ability: AbilityData, caster_idx: int) -> void:
	caster_index = caster_idx
	_cast_duration = ability.cast_time
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_theme_constant_override("separation", 4)

	var icon := TextureRect.new()
	icon.texture = ability.icon
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	icon.size = Vector2(ICON_SIZE, ICON_SIZE)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon)

	_bar = StatusBar.new()
	add_child(_bar)
	_bar.setup(BAR_BASE, BAR_FILL, 2)
	_bar.set_fill_color(Color(1.0, 0.3, 0.2))
	_bar.update_value(0.0, _cast_duration)


func _process(delta: float) -> void:
	_cast_timer += delta
	if _bar:
		_bar.update_value(_cast_timer, _cast_duration)
