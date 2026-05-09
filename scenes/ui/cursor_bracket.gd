extends Node2D

const CURSOR_SPRITE := preload("res://Tiny Swords (Free Pack)/UI Elements/UI Elements/Cursors/Cursor_04.png")
const BOUNCE_AMOUNT := 10.0
const BOUNCE_DURATION := 0.5

const REGIONS := [
	Rect2(0, 0, 40, 40),
	Rect2(88, 0, 40, 40),
	Rect2(0, 88, 40, 40),
	Rect2(88, 88, 40, 40),
]

const DIRS := [
	Vector2(-1, -1),
	Vector2(1, -1),
	Vector2(-1, 1),
	Vector2(1, 1),
]

var _corners: Array[Sprite2D] = []
var _base_positions: PackedVector2Array = []
var _bounce_tween: Tween


func wrap(control: Control, padding_x: float = 0.0, padding_y: float = 0.0) -> void:
	wrap_rect(Rect2(control.position, control.size), padding_x, padding_y)


func wrap_rect(rect: Rect2, padding_x: float = 0.0, padding_y: float = 0.0) -> void:
	rect = rect.grow_individual(padding_x, padding_y, padding_x, padding_y)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	var corner_size := REGIONS[0].size

	_base_positions = PackedVector2Array([
		Vector2(rect.position.x - corner_size.x, rect.position.y - corner_size.y),
		Vector2(rect.end.x, rect.position.y - corner_size.y),
		Vector2(rect.position.x - corner_size.x, rect.end.y),
		Vector2(rect.end.x, rect.end.y),
	])

	for i in 4:
		var sprite := Sprite2D.new()
		var atlas := AtlasTexture.new()
		atlas.atlas = CURSOR_SPRITE
		atlas.region = REGIONS[i]
		sprite.texture = atlas
		sprite.centered = false
		sprite.position = _base_positions[i]
		add_child(sprite)
		_corners.append(sprite)

	_start_bounce()


func _start_bounce() -> void:
	if _bounce_tween and _bounce_tween.is_valid():
		_bounce_tween.kill()

	_bounce_tween = create_tween().set_loops()

	for i in 4:
		var expanded: Vector2 = _base_positions[i] + DIRS[i] * BOUNCE_AMOUNT
		if i == 0:
			_bounce_tween.tween_property(_corners[i], "position", expanded, BOUNCE_DURATION) \
				.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		else:
			_bounce_tween.parallel().tween_property(_corners[i], "position", expanded, BOUNCE_DURATION) \
				.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	for i in 4:
		if i == 0:
			_bounce_tween.tween_property(_corners[i], "position", _base_positions[i], BOUNCE_DURATION) \
				.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		else:
			_bounce_tween.parallel().tween_property(_corners[i], "position", _base_positions[i], BOUNCE_DURATION) \
				.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
