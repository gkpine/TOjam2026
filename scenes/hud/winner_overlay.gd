class_name WinnerOverlay
extends Control

const CursorBracketScene := preload("res://scenes/ui/cursor_bracket.tscn")
const OVERLAY_COLOR := Color(0.0, 0.0, 0.0, 0.55)
const TITLE_COLOR := Color(1.0, 0.85, 0.1)
const SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.7)
const OPTION_GAP := 20.0
const OPTION_LABELS := ["Play Again", "Main Menu"]

var _banners: Array[PaperBanner] = []
var _bracket: Node2D = null
var _selected_index: int = 0
var _input_index: int = 0


func setup(player_index: int, survival_seconds: float) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	if player_index < GameState.cpu_players.size() and GameState.cpu_players[player_index]:
		_input_index = 0
	else:
		_input_index = player_index

	var vp_size := get_viewport_rect().size
	size = vp_size

	var overlay := ColorRect.new()
	overlay.size = vp_size
	overlay.color = OVERLAY_COLOR
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	var title := Label.new()
	title.text = "WINNER"
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", TITLE_COLOR)
	title.add_theme_color_override("font_shadow_color", SHADOW_COLOR)
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.anchor_left = 0.0
	title.anchor_right = 1.0
	title.anchor_top = 0.5
	title.offset_top = -120.0
	title.offset_bottom = -50.0
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)

	var minutes := int(survival_seconds) / 60
	var seconds := int(survival_seconds) % 60
	var subtitle := Label.new()
	subtitle.text = "You lasted %dm:%02ds" % [minutes, seconds]
	subtitle.add_theme_font_size_override("font_size", 28)
	subtitle.add_theme_color_override("font_color", Color.WHITE)
	subtitle.add_theme_color_override("font_shadow_color", SHADOW_COLOR)
	subtitle.add_theme_constant_override("shadow_offset_x", 2)
	subtitle.add_theme_constant_override("shadow_offset_y", 2)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.anchor_left = 0.0
	subtitle.anchor_right = 1.0
	subtitle.anchor_top = 0.5
	subtitle.offset_top = -40.0
	subtitle.offset_bottom = 0.0
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(subtitle)

	for i in range(OPTION_LABELS.size()):
		var banner := PaperBanner.new()
		banner.setup(2, 0)
		add_child(banner)
		var banner_size := banner.get_banner_size()

		var label := Label.new()
		label.text = OPTION_LABELS[i]
		label.add_theme_font_size_override("font_size", 52)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.position = Vector2(20.0, 0.0)
		label.size = Vector2(banner_size.x - 40.0, banner_size.y - 20.0)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		banner.add_child(label)

		# Transparent Button overlay catches mouse clicks and hover. Sits on top
		# of the banner art with no visuals (flat + transparent modulate) so the
		# paper banner texture still shows through. Click confirms immediately;
		# hover updates the selection so the bracket follows the mouse.
		#
		# PROCESS_MODE_ALWAYS is needed because the game tree is paused while
		# the winner overlay is shown — without it, the GUI system filters out
		# the click dispatch even though hover events still arrive through the
		# engine's continuous mouse-position tracking.
		var click := Button.new()
		click.process_mode = Node.PROCESS_MODE_ALWAYS
		click.size = banner_size
		click.flat = true
		click.modulate = Color(1, 1, 1, 0)
		click.focus_mode = Control.FOCUS_NONE
		click.mouse_filter = Control.MOUSE_FILTER_STOP
		click.pressed.connect(_on_option_clicked.bind(i))
		click.mouse_entered.connect(_on_option_hovered.bind(i))
		banner.add_child(click)

		_banners.append(banner)

	_position_options(vp_size)
	_update_selection()


func _position_options(vp_size: Vector2) -> void:
	var n := _banners.size()
	var banner_size := _banners[0].get_banner_size()
	var total_width := n * banner_size.x + (n - 1) * OPTION_GAP
	var x_start := (vp_size.x - total_width) / 2.0
	var y_pos := vp_size.y / 2.0 + 20.0

	for i in range(n):
		_banners[i].position = Vector2(x_start + i * (banner_size.x + OPTION_GAP), y_pos)


func _process(_delta: float) -> void:
	if InputManager.is_action_just_pressed(_input_index, "move_left"):
		_selected_index = maxi(_selected_index - 1, 0)
		_update_selection()
	elif InputManager.is_action_just_pressed(_input_index, "move_right"):
		_selected_index = mini(_selected_index + 1, _banners.size() - 1)
		_update_selection()

	# `switch_target` covers Space (kb) and A button (controller) per the
	# project's InputManager. `ui_accept` is Godot's built-in confirm action,
	# bound to Enter (and Space) by default — adds Enter without touching
	# in-game bindings where switch_target also means "cycle target."
	if InputManager.is_action_just_pressed(_input_index, "switch_target") \
			or Input.is_action_just_pressed("ui_accept"):
		_confirm_selection()


func _update_selection() -> void:
	if _bracket:
		_bracket.queue_free()
		_bracket = null
	var banner := _banners[_selected_index]
	_bracket = CursorBracketScene.instantiate()
	banner.add_child(_bracket)
	_bracket.wrap_rect(Rect2(Vector2.ZERO, banner.get_banner_size()), -32.0, -32.0)


func _on_option_clicked(idx: int) -> void:
	_selected_index = idx
	_update_selection()
	_confirm_selection()


func _on_option_hovered(idx: int) -> void:
	if _selected_index == idx:
		return
	_selected_index = idx
	_update_selection()


func _confirm_selection() -> void:
	match _selected_index:
		0:
			_play_again()
		1:
			_main_menu()


func _play_again() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/game/game.tscn")


func _main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")
