extends Control

var _selected_count: int = 0
var _cpu_toggles: Array[Button] = []

@onready var _start_button: Button = %StartButton
@onready var _btn_2: Button = %Btn2
@onready var _btn_4: Button = %Btn4
@onready var _player_config: VBoxContainer = %PlayerConfigContainer
@onready var _title_label: Label = $CenterContainer/VBoxContainer/TitleLabel
@onready var _goat: Sprite2D = $Goat

var _goat_velocity: Vector2 = Vector2(180, 140)
var _goat_angular_velocity: float = 1.2  # radians/sec


func _ready() -> void:
	_btn_2.pressed.connect(_on_count_selected.bind(2))
	_btn_4.pressed.connect(_on_count_selected.bind(4))
	_start_button.pressed.connect(_on_start)
	_start_button.disabled = true
	_player_config.visible = false
	_start_title_bulge()


func _process(delta: float) -> void:
	_animate_goat(delta)


func _animate_goat(delta: float) -> void:
	_goat.position += _goat_velocity * delta
	_goat.rotation += _goat_angular_velocity * delta

	# Bounce off the viewport edges. Use the un-rotated half-extents (texture
	# size × scale × 0.5) as the bounce boundary — close enough for the visual,
	# and stable as the sprite rotates. The velocity-sign guard prevents getting
	# stuck flipping at an edge if the sprite spawns partway past it.
	var screen := get_viewport_rect().size
	var tex := _goat.texture.get_size()
	var half_w: float = tex.x * _goat.scale.x * 0.5
	var half_h: float = tex.y * _goat.scale.y * 0.5
	if _goat.position.x - half_w < 0.0 and _goat_velocity.x < 0.0:
		_goat_velocity.x = -_goat_velocity.x
	elif _goat.position.x + half_w > screen.x and _goat_velocity.x > 0.0:
		_goat_velocity.x = -_goat_velocity.x
	if _goat.position.y - half_h < 0.0 and _goat_velocity.y < 0.0:
		_goat_velocity.y = -_goat_velocity.y
	elif _goat.position.y + half_h > screen.y and _goat_velocity.y > 0.0:
		_goat_velocity.y = -_goat_velocity.y


func _start_title_bulge() -> void:
	# Wait one frame so the VBoxContainer has resolved the label's size; otherwise
	# pivot_offset would be (0, 0) and the bulge would pivot from the top-left
	# corner instead of the label's center.
	await get_tree().process_frame
	_title_label.pivot_offset = _title_label.size / 2.0
	var tween := create_tween().set_loops()
	tween.tween_property(_title_label, "scale", Vector2(1.12, 1.12), 0.7) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_title_label, "scale", Vector2(1.0, 1.0), 0.7) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _on_count_selected(count: int) -> void:
	_selected_count = count
	GameState.player_count = count
	_start_button.disabled = false
	_btn_2.button_pressed = (count == 2)
	_btn_4.button_pressed = (count == 4)
	_build_player_config(count)


func _build_player_config(count: int) -> void:
	for child in _player_config.get_children():
		child.queue_free()
	_cpu_toggles.clear()
	_player_config.visible = true

	for i in range(count):
		var hbox := HBoxContainer.new()
		var label := Label.new()
		label.text = "Player %d:" % (i + 1)
		label.custom_minimum_size.x = 100.0
		hbox.add_child(label)

		var toggle := Button.new()
		toggle.toggle_mode = true
		toggle.custom_minimum_size.x = 80.0
		if i == 0:
			toggle.button_pressed = false
			toggle.text = "Human"
		else:
			toggle.button_pressed = true
			toggle.text = "CPU"
		toggle.toggled.connect(_on_cpu_toggled.bind(toggle))
		hbox.add_child(toggle)
		_player_config.add_child(hbox)
		_cpu_toggles.append(toggle)


func _on_cpu_toggled(pressed: bool, button: Button) -> void:
	button.text = "CPU" if pressed else "Human"


func _on_start() -> void:
	GameState.cpu_players.clear()
	for i in range(_selected_count):
		var is_cpu := _cpu_toggles[i].button_pressed if i < _cpu_toggles.size() else false
		GameState.cpu_players.append(is_cpu)
	get_tree().change_scene_to_file("res://scenes/game/game.tscn")
