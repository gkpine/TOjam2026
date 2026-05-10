class_name PaperBanner
extends Control

const BANNER_TEX := preload("res://assets/ui/banner.png")

const TL_REGION := Rect2(28, 60, 100, 68)
const TC_REGION := Rect2(192, 60, 64, 68)
const ML_REGION := Rect2(28, 192, 100, 64)
const CC_REGION := Rect2(192, 192, 64, 64)
const BL_REGION := Rect2(28, 320, 100, 104)
const BC_REGION := Rect2(192, 320, 64, 77)

const EDGE_W := 100.0
const TILE_W := 64.0
const TOP_H := 68.0
const MID_H := 64.0
const BOT_H := 104.0

var _flipped_cache: Dictionary = {}
var _h_tiles: int = 1
var _v_tiles: int = 1


func setup(h_tiles: int = 1, v_tiles: int = 1) -> void:
	_h_tiles = h_tiles
	_v_tiles = v_tiles
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	_add_piece(TL_REGION, Vector2(0, 0))
	for i in h_tiles:
		_add_piece(TC_REGION, Vector2(EDGE_W + i * TILE_W, 0))
	_add_flipped_piece(TL_REGION, Vector2(EDGE_W + h_tiles * TILE_W, 0))

	for v in v_tiles:
		var row_y := TOP_H + v * MID_H
		_add_piece(ML_REGION, Vector2(0, row_y))
		for i in h_tiles:
			_add_piece(CC_REGION, Vector2(EDGE_W + i * TILE_W, row_y))
		_add_flipped_piece(ML_REGION, Vector2(EDGE_W + h_tiles * TILE_W, row_y))

	var bot_y := TOP_H + v_tiles * MID_H
	_add_piece(BL_REGION, Vector2(0, bot_y))
	for i in h_tiles:
		_add_piece(BC_REGION, Vector2(EDGE_W + i * TILE_W, bot_y))
	_add_flipped_piece(BL_REGION, Vector2(EDGE_W + h_tiles * TILE_W, bot_y))

	var total := get_banner_size()
	custom_minimum_size = total
	size = total


func setup_for_size(target_width: float, target_height: float) -> void:
	var h := maxi(1, ceili((target_width - 2.0 * EDGE_W) / TILE_W))
	var v := maxi(1, ceili((target_height - TOP_H - BOT_H) / MID_H))
	setup(h, v)


func get_banner_size() -> Vector2:
	return Vector2(
		2.0 * EDGE_W + TILE_W * _h_tiles,
		TOP_H + MID_H * _v_tiles + BOT_H
	)


func get_content_rect() -> Rect2:
	return Rect2(EDGE_W, TOP_H, TILE_W * _h_tiles, MID_H * _v_tiles)


func _add_piece(region: Rect2, pos: Vector2) -> void:
	var tex_rect := TextureRect.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = BANNER_TEX
	atlas.region = region
	atlas.filter_clip = true
	tex_rect.texture = atlas
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP
	tex_rect.position = pos
	tex_rect.size = region.size
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tex_rect)


func _add_flipped_piece(region: Rect2, pos: Vector2) -> void:
	var tex_rect := TextureRect.new()
	tex_rect.texture = _get_flipped_texture(region)
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP
	tex_rect.position = pos
	tex_rect.size = region.size
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tex_rect)


func _get_flipped_texture(region: Rect2) -> ImageTexture:
	if _flipped_cache.has(region):
		return _flipped_cache[region]
	var img := BANNER_TEX.get_image()
	var sub := img.get_region(Rect2i(region))
	sub.flip_x()
	var tex := ImageTexture.create_from_image(sub)
	_flipped_cache[region] = tex
	return tex
