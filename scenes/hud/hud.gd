extends CanvasLayer

const SMALL_BAR_BASE := preload("res://Tiny Swords (Free Pack)/UI Elements/UI Elements/Bars/SmallBar_Base.png")
const SMALL_BAR_FILL := preload("res://Tiny Swords (Free Pack)/UI Elements/UI Elements/Bars/SmallBar_Fill.png")
const FONT := preload("res://assets/fonts/VT323-Regular.ttf")
const MARGIN := 16.0
const XP_BAR_HEIGHT := 42.0

var _player: Player = null
var _xp_bar: StatusBar
var _level_label: Label

@onready var health_bar: Control = $HealthBar
@onready var action_bar: Control = $ActionBar


func setup(player: Player) -> void:
	_player = player
	health_bar.update_health(player.health, player.max_health)
	action_bar.setup(player)
	player.health_changed.connect(_on_player_health_changed)
	player.died.connect(_on_player_died)

	_xp_bar = StatusBar.new()
	add_child(_xp_bar)
	_xp_bar.setup(SMALL_BAR_BASE, SMALL_BAR_FILL, 3)
	_xp_bar.anchor_left = 0.0
	_xp_bar.anchor_top = 1.0
	_xp_bar.anchor_right = 0.0
	_xp_bar.anchor_bottom = 1.0
	var xp_width := _xp_bar.get_bar_width()
	_xp_bar.offset_left = MARGIN
	_xp_bar.offset_top = -(XP_BAR_HEIGHT + MARGIN)
	_xp_bar.offset_right = MARGIN + xp_width
	_xp_bar.offset_bottom = -MARGIN
	_xp_bar.set_fill_color(Color(0.95, 0.5, 1.0))

	_level_label = Label.new()
	_level_label.text = "Lv. %d" % player.level
	_level_label.add_theme_font_override("font", FONT)
	_level_label.add_theme_font_size_override("font_size", 32)
	_level_label.add_theme_color_override("font_color", Color.WHITE)
	_level_label.add_theme_constant_override("outline_size", 4)
	_level_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_level_label.anchor_left = 0.0
	_level_label.anchor_top = 1.0
	_level_label.anchor_right = 0.0
	_level_label.anchor_bottom = 1.0
	_level_label.offset_left = MARGIN + xp_width + 4.0
	_level_label.offset_top = -(XP_BAR_HEIGHT + MARGIN) + 12
	_level_label.offset_bottom = -MARGIN
	add_child(_level_label)

	player.experience_changed.connect(_on_player_experience_changed)
	player.leveled_up.connect(_on_player_leveled_up)

	var xp_req := player.LEVEL_DATA.get_xp_required(player.level)
	if xp_req > 0.0:
		_xp_bar.update_value(player.experience, xp_req)
	else:
		_xp_bar.update_value(0.0, 1.0)


func _on_player_health_changed(amount: int, _world_pos: Vector2, change_type: String) -> void:
	if _player == null:
		return
	var is_heal := amount > 0
	health_bar.spawn_floating_number(absi(amount), is_heal, change_type)
	health_bar.update_health(_player.health, _player.max_health)


func _on_player_experience_changed(current_xp: float, xp_required: float) -> void:
	_xp_bar.update_value(current_xp, xp_required)


func _on_player_leveled_up(new_level: int) -> void:
	_level_label.text = "Lv. %d" % new_level


func _on_player_died(_character: Character) -> void:
	if _player:
		health_bar.update_health(0.0, _player.max_health)
	_player = null
