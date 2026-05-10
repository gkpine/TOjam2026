extends Control

var _selected_count: int = 0
var _cpu_toggles: Array[Button] = []

@onready var _start_button: Button = %StartButton
@onready var _btn_2: Button = %Btn2
@onready var _btn_4: Button = %Btn4
@onready var _player_config: VBoxContainer = %PlayerConfigContainer


func _ready() -> void:
	_btn_2.pressed.connect(_on_count_selected.bind(2))
	_btn_4.pressed.connect(_on_count_selected.bind(4))
	_start_button.pressed.connect(_on_start)
	_start_button.disabled = true
	_player_config.visible = false


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
