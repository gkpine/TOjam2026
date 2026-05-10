class_name DeathOverlay
extends Control

const OVERLAY_COLOR := Color(0.0, 0.0, 0.0, 0.65)
const TITLE_COLOR := Color(0.9, 0.15, 0.15)
const SUBTITLE_COLOR := Color(1.0, 1.0, 1.0)
const SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.7)


func setup(survival_seconds: float) -> void:
	var vp_size := get_viewport_rect().size
	size = vp_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var overlay := ColorRect.new()
	overlay.size = vp_size
	overlay.color = OVERLAY_COLOR
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	var title := Label.new()
	title.text = "YOU DIED"
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", TITLE_COLOR)
	title.add_theme_color_override("font_shadow_color", SHADOW_COLOR)
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.anchor_left = 0.0
	title.anchor_right = 1.0
	title.anchor_top = 0.5
	title.offset_top = -60.0
	title.offset_bottom = 0.0
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)

	var minutes := int(survival_seconds) / 60
	var seconds := int(survival_seconds) % 60
	var subtitle := Label.new()
	subtitle.text = "You lasted %dm:%02ds" % [minutes, seconds]
	subtitle.add_theme_font_size_override("font_size", 28)
	subtitle.add_theme_color_override("font_color", SUBTITLE_COLOR)
	subtitle.add_theme_color_override("font_shadow_color", SHADOW_COLOR)
	subtitle.add_theme_constant_override("shadow_offset_x", 2)
	subtitle.add_theme_constant_override("shadow_offset_y", 2)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.anchor_left = 0.0
	subtitle.anchor_right = 1.0
	subtitle.anchor_top = 0.5
	subtitle.offset_top = 20.0
	subtitle.offset_bottom = 60.0
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(subtitle)
