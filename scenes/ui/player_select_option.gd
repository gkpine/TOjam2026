class_name PlayerSelectOption
extends Control

const CursorBracketScene := preload("res://scenes/ui/cursor_bracket.tscn")
const BAR_BASE := preload("res://assets/ui/small_bar_base.png")
const BAR_FILL := preload("res://assets/ui/small_bar_fill.png")
const FRAME_SIZE := 192
const SPRITE_DISPLAY_SIZE := 148.0
const OPTION_SIZE := Vector2(96, 96)

var _sprite: AnimatedSprite2D
var _health_bar: StatusBar
var _target_player: Player
var _bracket: Node2D = null
var _is_selected: bool = false
var _player_index: int = -1


func setup(target_index: int) -> void:
	_player_index = target_index
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = OPTION_SIZE
	size = OPTION_SIZE

	var n := target_index + 1
	var sheet: Texture2D = load("res://assets/players/player%d/player_%d_idle.png" % [n, n])
	var frames := SpriteFrames.new()
	frames.add_animation("idle")
	frames.set_animation_speed("idle", 10)
	frames.set_animation_loop("idle", true)
	for i in range(8):
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(i * FRAME_SIZE, 0, FRAME_SIZE, FRAME_SIZE)
		frames.add_frame("idle", atlas)
	frames.remove_animation("default")

	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = frames
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = Vector2.ONE * (SPRITE_DISPLAY_SIZE / float(FRAME_SIZE))
	_sprite.position = Vector2(OPTION_SIZE.x / 2.0, OPTION_SIZE.y / 2.0 - 12.0)
	_sprite.play("idle")
	add_child(_sprite)

	_health_bar = StatusBar.new()
	_health_bar.setup(BAR_BASE, BAR_FILL, 1)
	_health_bar.set_fill_color(Color(1.0, 0.2, 0.2))
	add_child(_health_bar)
	_health_bar.position = Vector2(
		(OPTION_SIZE.x - _health_bar.get_bar_width()) / 2.0,
		OPTION_SIZE.y - StatusBar.BAR_HEIGHT + 12.0
	)

	if target_index < GameState.players.size():
		var player := GameState.players[target_index] as Player
		if player and is_instance_valid(player):
			_target_player = player
			_health_bar.update_value(player.health, player.get_effective_stat("max_health"))
			player.health_changed.connect(_on_health_changed)


func set_selected(selected: bool) -> void:
	if _is_selected == selected:
		return
	_is_selected = selected
	if _is_selected:
		_bracket = CursorBracketScene.instantiate()
		add_child(_bracket)
		_bracket.wrap_rect(Rect2(Vector2.ZERO, OPTION_SIZE), -20.0, -20.0)
	else:
		if _bracket:
			_bracket.queue_free()
			_bracket = null


func get_target_index() -> int:
	return _player_index


func _on_health_changed(_amount: int, _world_pos: Vector2, _change_type: String) -> void:
	if _target_player and is_instance_valid(_target_player) and _health_bar:
		_health_bar.update_value(_target_player.health, _target_player.get_effective_stat("max_health"))
