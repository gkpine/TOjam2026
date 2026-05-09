class_name UpgradeOption
extends Control

const FONT := preload("res://assets/fonts/VT323-Regular.ttf")
const CursorBracketScene := preload("res://scenes/ui/cursor_bracket.tscn")
const BANNER_H_TILES := 1
const BANNER_V_TILES := 0

var _banner: PaperBanner
var _bracket: Node2D
var _is_selected: bool = false


func setup(upgrade: UpgradeData) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_banner = PaperBanner.new()
	_banner.setup(BANNER_H_TILES, BANNER_V_TILES)
	add_child(_banner)

	var banner_size := _banner.get_banner_size()
	var text_inset := 16.0
	var text_width := banner_size.x - text_inset * 2.0

	var name_label := Label.new()
	name_label.text = upgrade.upgrade_name
	name_label.add_theme_font_override("font", FONT)
	name_label.add_theme_font_size_override("font_size", 28)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.add_theme_constant_override("outline_size", 4)
	name_label.add_theme_color_override("font_outline_color", Color.BLACK)
	name_label.position = Vector2(text_inset, 20)
	name_label.size = Vector2(text_width, 32)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = upgrade.description
	desc_label.add_theme_font_override("font", FONT)
	desc_label.add_theme_font_size_override("font_size", 20)
	desc_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.85))
	desc_label.add_theme_constant_override("outline_size", 2)
	desc_label.add_theme_color_override("font_outline_color", Color.BLACK)
	desc_label.position = Vector2(text_inset, 52)
	desc_label.size = Vector2(text_width, banner_size.y - 68)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.add_child(desc_label)

	custom_minimum_size = banner_size
	size = banner_size


func set_selected(selected: bool) -> void:
	if _is_selected == selected:
		return
	_is_selected = selected
	if _is_selected:
		_bracket = CursorBracketScene.instantiate()
		_banner.add_child(_bracket)
		var content := _banner.get_content_rect()
		_bracket.wrap_rect(content)
	else:
		if _bracket:
			_bracket.queue_free()
			_bracket = null
