extends CanvasLayer

const SMALL_BAR_BASE := preload("res://Tiny Swords (Free Pack)/UI Elements/UI Elements/Bars/SmallBar_Base.png")
const SMALL_BAR_FILL := preload("res://Tiny Swords (Free Pack)/UI Elements/UI Elements/Bars/SmallBar_Fill.png")
const MARGIN := 16.0
const XP_BAR_HEIGHT := 42.0

var _player: Player = null
var _world_index: int = 0
var _xp_bar: StatusBar
var _level_label: Label
var _level_up_prompt: Label
var _prompt_tween: Tween = null
var _number_scene: PackedScene = preload("res://scenes/combat/floating_combat_number.tscn")

@onready var health_bar: Control = $HealthBar
@onready var action_bar: Control = $ActionBar


func setup(player: Player) -> void:
	_player = player
	_world_index = player.player_index
	health_bar.update_health(player.health, player.get_effective_stat("max_health"))
	action_bar.setup(player)
	player.health_changed.connect(_on_player_health_changed)
	player.died.connect(_on_player_died)
	GameState.player_died.connect(_on_game_player_died)
	GameState.winner_declared.connect(_on_winner_declared)

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
	_level_label.add_theme_font_size_override("font_size", 32)
	_level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_level_label.anchor_left = 0.0
	_level_label.anchor_top = 1.0
	_level_label.anchor_right = 0.0
	_level_label.anchor_bottom = 1.0
	_level_label.offset_left = MARGIN + xp_width + 4.0
	_level_label.offset_top = -(XP_BAR_HEIGHT + MARGIN) + 12
	_level_label.offset_bottom = -MARGIN
	add_child(_level_label)

	var upgrade_ui := UpgradeOptionsController.new()
	add_child(upgrade_ui)
	upgrade_ui.setup(player)

	var target_ui := PlayerSelectController.new()
	add_child(target_ui)
	target_ui.setup(player)

	var casting_display := OtherPlayerCastingDisplayController.new()
	add_child(casting_display)
	casting_display.setup(_world_index)

	_level_up_prompt = Label.new()
	_level_up_prompt.add_theme_font_size_override("font_size", 24)
	_level_up_prompt.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	_level_up_prompt.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	_level_up_prompt.add_theme_constant_override("shadow_offset_x", 2)
	_level_up_prompt.add_theme_constant_override("shadow_offset_y", 2)
	_level_up_prompt.anchor_left = 0.0
	_level_up_prompt.anchor_top = 1.0
	_level_up_prompt.anchor_right = 0.0
	_level_up_prompt.anchor_bottom = 1.0
	_level_up_prompt.offset_left = MARGIN
	_level_up_prompt.offset_top = -136.0
	_level_up_prompt.offset_bottom = -104.0
	_level_up_prompt.visible = false
	add_child(_level_up_prompt)

	player.experience_changed.connect(_on_player_experience_changed)
	player.leveled_up.connect(_on_player_leveled_up)
	player.upgrade_selection_completed.connect(_on_upgrade_completed)

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
	health_bar.update_health(_player.health, _player.get_effective_stat("max_health"))


func _on_player_experience_changed(current_xp: float, xp_required: float) -> void:
	_xp_bar.update_value(current_xp, xp_required)


func _on_player_leveled_up(new_level: int) -> void:
	_level_label.text = "Lv. %d" % new_level
	_update_level_up_prompt()
	_spawn_level_up_text()


func _on_upgrade_completed() -> void:
	_update_level_up_prompt()


func _on_player_died(_character: Character) -> void:
	if _player:
		health_bar.update_health(0.0, _player.get_effective_stat("max_health"))
	_player = null
	_update_level_up_prompt()


func _update_level_up_prompt() -> void:
	if _player == null or _player.pending_upgrade_count <= 0:
		_level_up_prompt.visible = false
		_stop_bounce_animation()
		return
	var key := InputManager.get_action_label(_player.player_index, "open_upgrades")
	_level_up_prompt.text = "[%s] Level Up! Select an upgrade." % key
	_level_up_prompt.visible = true
	_start_bounce_animation()


func _start_bounce_animation() -> void:
	if _prompt_tween != null and _prompt_tween.is_valid():
		return
	_prompt_tween = create_tween().set_loops()
	_prompt_tween.tween_property(_level_up_prompt, "offset_top", -140.0, 0.5) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_prompt_tween.tween_property(_level_up_prompt, "offset_top", -136.0, 0.5) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func _stop_bounce_animation() -> void:
	if _prompt_tween != null and _prompt_tween.is_valid():
		_prompt_tween.kill()
		_prompt_tween = null


func _on_game_player_died(player_index: int) -> void:
	if player_index != _world_index:
		return
	var survival := GameState.get_survival_seconds()
	var overlay := DeathOverlay.new()
	add_child(overlay)
	overlay.setup(survival)


func _on_winner_declared(winner_index: int) -> void:
	if winner_index != _world_index:
		return
	var survival := GameState.get_survival_seconds()
	var overlay := WinnerOverlay.new()
	add_child(overlay)
	overlay.setup(winner_index, survival)


func _spawn_level_up_text() -> void:
	var number := _number_scene.instantiate()
	number.custom_text = "[color=gold][font_size=64]LEVEL UP![/font_size][/color]"
	number.anim_config = {
		"duration": 1.5,
		"bounce_scale": 1.4,
		"bounce_start": 0.0,
		"bounce_end": 0.4,
		"float_start": 0.2,
		"float_end": 1.0,
		"float_distance": 60.0,
		"fade_start": 0.6,
		"fade_end": 1.0,
	}
	var vp_size := get_viewport().get_visible_rect().size
	number.position = Vector2(vp_size.x / 2.0, vp_size.y * 0.35)
	add_child(number)
