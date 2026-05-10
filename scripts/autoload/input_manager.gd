extends Node

const MOVEMENT_ACTIONS := ["move_up", "move_down", "move_left", "move_right"]
const BUTTON_ACTIONS := ["switch_target", "ability_1", "ability_2", "ability_3", "ability_4", "open_upgrades"]

const KB_BINDINGS := {
	"move_up": KEY_W,
	"move_down": KEY_S,
	"move_left": KEY_A,
	"move_right": KEY_D,
	"switch_target": KEY_SPACE,
	"ability_1": KEY_1,
	"ability_2": KEY_2,
	"ability_3": KEY_3,
	"ability_4": KEY_4,
	"open_upgrades": KEY_U,
}

const JOY_BUTTON_BINDINGS := {
	"switch_target": JOY_BUTTON_A,
	"ability_1": JOY_BUTTON_X,
	"ability_2": JOY_BUTTON_Y,
	"ability_3": JOY_BUTTON_RIGHT_SHOULDER,
	"ability_4": JOY_BUTTON_LEFT_SHOULDER,
	"open_upgrades": JOY_BUTTON_DPAD_UP,
}

const KB_DISPLAY_NAMES := {
	"ability_1": "1",
	"ability_2": "2",
	"ability_3": "3",
	"ability_4": "4",
}

const JOY_DISPLAY_NAMES := {
	"ability_1": "X",
	"ability_2": "Y",
	"ability_3": "RB",
	"ability_4": "LB",
}

const STICK_AXES := {
	"move_up": [JOY_AXIS_LEFT_Y, -1.0],
	"move_down": [JOY_AXIS_LEFT_Y, 1.0],
	"move_left": [JOY_AXIS_LEFT_X, -1.0],
	"move_right": [JOY_AXIS_LEFT_X, 1.0],
}


func _ready() -> void:
	_setup_input_map()


func _setup_input_map() -> void:
	var all_actions := MOVEMENT_ACTIONS + BUTTON_ACTIONS
	for player_idx in range(4):
		for action_name in all_actions:
			var full_action := "p%d_%s" % [player_idx + 1, action_name]

			if not InputMap.has_action(full_action):
				InputMap.add_action(full_action)

			if player_idx == 0 and action_name in KB_BINDINGS:
				var kb_event := InputEventKey.new()
				kb_event.keycode = KB_BINDINGS[action_name]
				InputMap.action_add_event(full_action, kb_event)

			if player_idx > 0 and action_name in STICK_AXES:
				var joy_event := InputEventJoypadMotion.new()
				joy_event.device = player_idx - 1
				joy_event.axis = STICK_AXES[action_name][0]
				joy_event.axis_value = STICK_AXES[action_name][1]
				InputMap.action_add_event(full_action, joy_event)

			if player_idx > 0 and action_name in JOY_BUTTON_BINDINGS:
				var btn_event := InputEventJoypadButton.new()
				btn_event.device = player_idx - 1
				btn_event.button_index = JOY_BUTTON_BINDINGS[action_name]
				InputMap.action_add_event(full_action, btn_event)


func get_movement_vector(player_index: int) -> Vector2:
	var prefix := "p%d_" % (player_index + 1)
	return Input.get_vector(
		prefix + "move_left",
		prefix + "move_right",
		prefix + "move_up",
		prefix + "move_down"
	)


func is_action_just_pressed(player_index: int, action: String) -> bool:
	return Input.is_action_just_pressed("p%d_%s" % [player_index + 1, action])


func get_ability_label(player_index: int, slot_index: int) -> String:
	var action := "ability_%d" % (slot_index + 1)
	if player_index == 0:
		return KB_DISPLAY_NAMES.get(action, "")
	return JOY_DISPLAY_NAMES.get(action, "")
