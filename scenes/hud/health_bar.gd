extends Control

const BAR_BASE := preload("res://Tiny Swords (Free Pack)/UI Elements/UI Elements/Bars/BigBar_Base.png")
const BAR_FILL := preload("res://Tiny Swords (Free Pack)/UI Elements/UI Elements/Bars/BigBar_Fill.png")

const LEFT_REGION := Rect2(40, 0, 24, 64)
const CENTER_REGION := Rect2(128, 0, 64, 64)
const RIGHT_REGION := Rect2(256, 0, 24, 64)
const CENTER_TILES := 3
const BAR_HEIGHT := 64.0
const MARGIN := 16.0
const FILL_CAP_INSET := 12.0

var _fill: TextureRect
var _fill_max_width: float


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	var x := 0.0

	_add_piece(LEFT_REGION, x)
	x += LEFT_REGION.size.x

	for i in CENTER_TILES:
		_add_piece(CENTER_REGION, x)
		x += CENTER_REGION.size.x

	_add_piece(RIGHT_REGION, x)
	x += RIGHT_REGION.size.x

	_fill_max_width = FILL_CAP_INSET + CENTER_REGION.size.x * CENTER_TILES + FILL_CAP_INSET
	_fill = TextureRect.new()
	_fill.texture = BAR_FILL
	_fill.stretch_mode = TextureRect.STRETCH_SCALE
	_fill.position = Vector2(LEFT_REGION.size.x - FILL_CAP_INSET, 0)
	_fill.size = Vector2(_fill_max_width, BAR_HEIGHT)
	_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fill)

	custom_minimum_size = Vector2(x, BAR_HEIGHT)
	size = Vector2(x, BAR_HEIGHT)
	anchor_left = 0.0
	anchor_top = 1.0
	anchor_right = 0.0
	anchor_bottom = 1.0
	offset_left = MARGIN
	offset_top = -(BAR_HEIGHT + MARGIN)
	offset_right = MARGIN + x
	offset_bottom = -MARGIN


func _add_piece(region: Rect2, x_pos: float) -> void:
	var tex_rect := TextureRect.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = BAR_BASE
	atlas.region = region
	tex_rect.texture = atlas
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP
	tex_rect.position = Vector2(x_pos, 0)
	tex_rect.size = Vector2(region.size.x, BAR_HEIGHT)
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tex_rect)


func update_health(current: float, maximum: float) -> void:
	if _fill == null:
		return
	var ratio := clampf(current / maximum, 0.0, 1.0)
	_fill.size.x = _fill_max_width * ratio
