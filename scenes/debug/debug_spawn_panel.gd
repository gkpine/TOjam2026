class_name DebugSpawnPanel
extends CanvasLayer

# Dev tool: toggle with backtick (`), drag an enemy from the panel into the
# world to spawn it at the cursor. Mounted only inside player 0's world.

const TOGGLE_KEY := KEY_QUOTELEFT
const PANEL_OFFSET := Vector2(16, 16)
const PANEL_SIZE := Vector2(460, 480)
const ICON_SIZE := 64.0
const XP_BUTTON_AMOUNTS := [5, 10, 25]

var _world: Node2D
var _drop_root: Control
var _panel: Control
var _drag_icon: Control = null  # custom drag preview (Godot's set_drag_preview misaligns)


func _ready() -> void:
	layer = 11
	_world = get_parent()
	_build_ui()
	_drop_root.visible = false
	set_process(false)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.physical_keycode == TOGGLE_KEY:
		_drop_root.visible = not _drop_root.visible
		get_viewport().set_input_as_handled()


# Custom drag preview tracking. set_drag_preview() pins the control's top-left
# at the cursor and ignores position offsets, so we render our own.
func _process(_delta: float) -> void:
	if _drag_icon == null:
		set_process(false)
		return
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_kill_drag_icon()
		return
	var mouse := _drop_root.get_global_mouse_position()
	_drag_icon.global_position = mouse - Vector2(ICON_SIZE, ICON_SIZE) / 2.0


func _build_ui() -> void:
	_drop_root = Control.new()
	_drop_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_drop_root.mouse_filter = Control.MOUSE_FILTER_PASS
	# Drop zone forwards to our handlers; never acts as a drag source.
	_drop_root.set_drag_forwarding(_no_drag, _can_drop, _do_drop)
	add_child(_drop_root)

	_panel = _build_panel()
	_drop_root.add_child(_panel)


func _build_panel() -> Control:
	var panel := PanelContainer.new()
	panel.position = PANEL_OFFSET
	panel.custom_minimum_size = PANEL_SIZE
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 8)
	panel.add_child(margin)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 12)
	margin.add_child(columns)

	columns.add_child(_build_enemy_column())
	columns.add_child(_build_controls_column())

	return panel


func _build_enemy_column() -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var title := Label.new()
	title.text = "Spawn Enemy  (drag)"
	col.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(scroll)

	var entries := VBoxContainer.new()
	entries.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entries.add_theme_constant_override("separation", 4)
	scroll.add_child(entries)

	for data in _get_enemy_types():
		entries.add_child(_build_entry(data))

	return col


func _build_controls_column() -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	col.custom_minimum_size = Vector2(140, 0)

	var title := Label.new()
	title.text = "Dev"
	col.add_child(title)

	var god_toggle := CheckButton.new()
	god_toggle.text = "God Mode"
	god_toggle.toggled.connect(_on_god_mode_toggled)
	col.add_child(god_toggle)

	var level_button := Button.new()
	level_button.text = "Level Up"
	level_button.pressed.connect(_on_level_up_pressed)
	col.add_child(level_button)

	var xp_label := Label.new()
	xp_label.text = "Add XP"
	col.add_child(xp_label)

	for amount in XP_BUTTON_AMOUNTS:
		var btn := Button.new()
		btn.text = "+%d" % amount
		btn.pressed.connect(_on_add_xp_pressed.bind(amount))
		col.add_child(btn)

	return col


func _build_entry(data: EnemyData) -> Control:
	var icon_tex := _make_icon(data)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	hbox.mouse_filter = Control.MOUSE_FILTER_STOP
	hbox.set_drag_forwarding(
		func(_at): return _start_drag(data, icon_tex),
		Callable(),
		Callable()
	)

	var icon := TextureRect.new()
	icon.texture = icon_tex
	icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(icon)

	var label := Label.new()
	label.text = data.enemy_name.capitalize()
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(label)

	return hbox


func _start_drag(data: EnemyData, icon_tex: Texture2D) -> Variant:
	# Custom preview: a Control parented to _drop_root, repositioned each frame
	# in _process() to follow the mouse. Centered on the cursor.
	_kill_drag_icon()
	var icon := TextureRect.new()
	icon.texture = icon_tex
	icon.size = Vector2(ICON_SIZE, ICON_SIZE)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate = Color(1, 1, 1, 0.85)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.top_level = true  # ignore parent transform; we set global_position directly
	_drop_root.add_child(icon)
	_drag_icon = icon
	set_process(true)
	return data


func _kill_drag_icon() -> void:
	if _drag_icon and is_instance_valid(_drag_icon):
		_drag_icon.queue_free()
	_drag_icon = null
	set_process(false)


func _no_drag(_at: Vector2) -> Variant:
	return null


func _can_drop(_at: Vector2, data: Variant) -> bool:
	return data is EnemyData


func _do_drop(_at: Vector2, data: Variant) -> void:
	if not (data is EnemyData):
		return
	if _world == null or not _world.has_method("spawn_enemy_at"):
		return
	_world.spawn_enemy_at(data, _world.get_global_mouse_position())


func _get_enemy_types() -> Array[EnemyData]:
	if _world == null or not _world.has_method("get_all_enemy_types"):
		return []
	return _world.get_all_enemy_types()


func _make_icon(data: EnemyData) -> Texture2D:
	var path := "res://assets/enemies/%s/%s_idle.png" % [data.enemy_name, data.enemy_name]
	var sheet := load(path) as Texture2D
	if sheet == null:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(0, 0, data.frame_size, data.frame_size)
	return atlas


# ---- Dev control callbacks ----

func _on_god_mode_toggled(enabled: bool) -> void:
	var p := _get_player()
	if p:
		p.god_mode = enabled


func _on_level_up_pressed() -> void:
	var p := _get_player()
	if p == null:
		return
	if p.level >= Player.LEVEL_DATA.max_level:
		return
	# Award exactly enough XP to trigger one level-up via the existing path.
	var needed := Player.LEVEL_DATA.get_xp_required(p.level) - p.experience
	p.gain_experience(maxf(needed, 0.0))


func _on_add_xp_pressed(amount: int) -> void:
	var p := _get_player()
	if p:
		p.gain_experience(float(amount))


func _get_player() -> Player:
	if _world == null:
		return null
	var p := _world.get("player") as Player
	if p and is_instance_valid(p):
		return p
	return null
