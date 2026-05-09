class_name StatusBar
extends Control

const LEFT_REGION := Rect2(40, 0, 24, 64)
const CENTER_REGION := Rect2(128, 0, 64, 64)
const RIGHT_REGION := Rect2(256, 0, 24, 64)
const BAR_HEIGHT := 64.0
const FILL_CAP_INSET := 12.0

var _fill: TextureRect
var _fill_max_width: float
var _bar_width: float


func setup(bar_base: Texture2D, bar_fill: Texture2D, center_tiles: int = 1) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	var x := 0.0
	_add_piece(bar_base, LEFT_REGION, x)
	x += LEFT_REGION.size.x
	for i in center_tiles:
		_add_piece(bar_base, CENTER_REGION, x)
		x += CENTER_REGION.size.x
	_add_piece(bar_base, RIGHT_REGION, x)
	x += RIGHT_REGION.size.x

	_fill_max_width = FILL_CAP_INSET + CENTER_REGION.size.x * center_tiles + FILL_CAP_INSET
	_fill = TextureRect.new()
	_fill.texture = bar_fill
	_fill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_fill.stretch_mode = TextureRect.STRETCH_SCALE
	_fill.position = Vector2(LEFT_REGION.size.x - FILL_CAP_INSET, 0)
	_fill.size = Vector2(_fill_max_width, BAR_HEIGHT)
	_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fill)

	_bar_width = x
	custom_minimum_size = Vector2(x, BAR_HEIGHT)
	size = Vector2(x, BAR_HEIGHT)


func _add_piece(bar_base: Texture2D, region: Rect2, x_pos: float) -> void:
	var tex_rect := TextureRect.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = bar_base
	atlas.region = region
	tex_rect.texture = atlas
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP
	tex_rect.position = Vector2(x_pos, 0)
	tex_rect.size = Vector2(region.size.x, BAR_HEIGHT)
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tex_rect)


func update_value(current: float, maximum: float) -> void:
	if _fill == null:
		return
	if maximum <= 0.0:
		_fill.size.x = _fill_max_width
		return
	var ratio := clampf(current / maximum, 0.0, 1.0)
	_fill.size.x = _fill_max_width * ratio


func get_bar_width() -> float:
	return _bar_width


func set_fill_color(color: Color) -> void:
	if _fill:
		_fill.modulate = color
