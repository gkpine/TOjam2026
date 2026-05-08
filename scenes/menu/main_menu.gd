extends Control

var selected_count: int = 0

@onready var start_button: Button = %StartButton
@onready var player_buttons: Array[Button] = [%Btn1, %Btn2, %Btn3, %Btn4]


func _ready() -> void:
	for i in range(4):
		player_buttons[i].pressed.connect(_on_count_selected.bind(i + 1))
	start_button.pressed.connect(_on_start)
	start_button.disabled = true


func _on_count_selected(count: int) -> void:
	selected_count = count
	GameState.player_count = count
	start_button.disabled = false
	for i in range(4):
		player_buttons[i].button_pressed = (i + 1 == count)


func _on_start() -> void:
	get_tree().change_scene_to_file("res://scenes/game/game.tscn")
