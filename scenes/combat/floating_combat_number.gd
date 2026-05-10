extends RichTextLabel

var amount: int = 0
var damage_type: String = "auto_attack"
var is_player_damage: bool = false
var is_heal: bool = false
var is_xp: bool = false
var custom_text: String = ""
var anim_config: Dictionary = {}


func _ready() -> void:
	modulate.a = 0.0
	bbcode_enabled = true
	fit_content = true
	scroll_active = false
	autowrap_mode = TextServer.AUTOWRAP_OFF

	add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	add_theme_constant_override("shadow_offset_x", 2)
	add_theme_constant_override("shadow_offset_y", 2)

	if custom_text != "":
		text = "[center]" + custom_text + "[/center]"
	else:
		var color_tag := ""
		var color_end := ""
		var prefix := ""
		var suffix := ""
		if is_heal:
			color_tag = "[color=green]"
			color_end = "[/color]"
			prefix = "+"
		elif is_xp:
			color_tag = "[color=#b366ff]"
			color_end = "[/color]"
			prefix = "+"
			suffix = "xp"
		elif is_player_damage:
			color_tag = "[color=red]"
			color_end = "[/color]"
		elif damage_type == "ability":
			color_tag = "[color=yellow]"
			color_end = "[/color]"
		text = "[center]" + color_tag + prefix + str(amount) + suffix + color_end + "[/center]"

	await get_tree().process_frame
	_start_animation()


func _start_animation() -> void:
	position -= size / 2.0
	pivot_offset = size / 2.0
	modulate.a = 1.0

	var dur: float = anim_config.get("duration", 1.0)

	var bounce_start: float = anim_config.get("bounce_start", 0.0) * dur
	var bounce_end: float = anim_config.get("bounce_end", 0.3) * dur
	var bounce_dur: float = bounce_end - bounce_start
	if bounce_dur > 0.0:
		var half: float = bounce_dur / 2.0
		var tween_bounce := create_tween()
		if bounce_start > 0.0:
			tween_bounce.tween_interval(bounce_start)
		tween_bounce.tween_property(self, "scale", Vector2.ONE * float(anim_config.get("bounce_scale", 1.3)), half) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween_bounce.tween_property(self, "scale", Vector2.ONE, half) \
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

	var float_start: float = anim_config.get("float_start", 0.1) * dur
	var float_end: float = anim_config.get("float_end", 1.0) * dur
	var float_dur: float = float_end - float_start
	if float_dur > 0.0:
		var tween_float := create_tween()
		if float_start > 0.0:
			tween_float.tween_interval(float_start)
		tween_float.tween_property(self, "position:y", position.y - float(anim_config.get("float_distance", 40.0)), float_dur) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	var fade_start: float = anim_config.get("fade_start", 0.5) * dur
	var fade_end: float = anim_config.get("fade_end", 1.0) * dur
	var fade_dur: float = fade_end - fade_start
	if fade_dur > 0.0:
		var tween_fade := create_tween()
		if fade_start > 0.0:
			tween_fade.tween_interval(fade_start)
		tween_fade.tween_property(self, "modulate:a", 0.0, fade_dur)

	await get_tree().create_timer(dur).timeout
	queue_free()
