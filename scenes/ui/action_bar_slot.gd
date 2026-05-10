class_name ActionBarSlot
extends Control

enum Variant { BLUE, RED }

const BLUE_REGULAR := preload("res://Tiny Swords (Free Pack)/UI Elements/UI Elements/Buttons/BigBlueButton_Regular.png")
const BLUE_PRESSED := preload("res://Tiny Swords (Free Pack)/UI Elements/UI Elements/Buttons/BigBlueButton_Pressed.png")
const RED_REGULAR := preload("res://Tiny Swords (Free Pack)/UI Elements/UI Elements/Buttons/BigRedButton_Regular.png")
const RED_PRESSED := preload("res://Tiny Swords (Free Pack)/UI Elements/UI Elements/Buttons/BigRedButton_Pressed.png")

const PIECE_SIZE := 64.0

const REGIONS := [
	Rect2(0, 0, 64, 64),
	Rect2(128, 0, 64, 64),
	Rect2(256, 0, 64, 64),
	Rect2(0, 128, 64, 64),
	Rect2(128, 128, 64, 64),
	Rect2(256, 128, 64, 64),
	Rect2(0, 256, 64, 64),
	Rect2(128, 256, 64, 64),
	Rect2(256, 256, 64, 64),
]

var _variant: Variant = Variant.BLUE
var _pressed: bool = false
var _desaturated: bool = false
var _pieces: Array[TextureRect] = []
var _icon_rect: TextureRect
var _cooldown_label: Label
var _keybind_label: Label
var _shader_material: ShaderMaterial


func setup(variant: Variant, slot_width: float, slot_height: float) -> void:
	_variant = variant
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	clip_contents = true
	custom_minimum_size = Vector2(slot_width, slot_height)
	size = Vector2(slot_width, slot_height)

	_setup_shader()
	_build_pieces(slot_width, slot_height)
	_build_icon(slot_width, slot_height)
	_build_cooldown_label(slot_width, slot_height)
	_build_keybind_label(slot_width, slot_height)


func _setup_shader() -> void:
	var shader := Shader.new()
	shader.code = "shader_type canvas_item;\nuniform float saturation : hint_range(0.0, 1.0) = 1.0;\nvoid fragment() {\n\tvec4 c = texture(TEXTURE, UV);\n\tfloat gray = dot(c.rgb, vec3(0.299, 0.587, 0.114));\n\tCOLOR = vec4(mix(vec3(gray), c.rgb, saturation), c.a);\n}\n"
	_shader_material = ShaderMaterial.new()
	_shader_material.shader = shader
	material = _shader_material


func _build_pieces(w: float, h: float) -> void:
	var corner := minf(minf(w / 2.0, h / 2.0), PIECE_SIZE)
	var inner_w := w - 2.0 * corner
	var inner_h := h - 2.0 * corner
	var tex := _get_texture()

	var layout := [
		[Vector2(0, 0), Vector2(corner, corner)],
		[Vector2(corner, 0), Vector2(inner_w, corner)],
		[Vector2(w - corner, 0), Vector2(corner, corner)],
		[Vector2(0, corner), Vector2(corner, inner_h)],
		[Vector2(corner, corner), Vector2(inner_w, inner_h)],
		[Vector2(w - corner, corner), Vector2(corner, inner_h)],
		[Vector2(0, h - corner), Vector2(corner, corner)],
		[Vector2(corner, h - corner), Vector2(inner_w, corner)],
		[Vector2(w - corner, h - corner), Vector2(corner, corner)],
	]

	for i in range(REGIONS.size()):
		var piece_size: Vector2 = layout[i][1]
		if piece_size.x <= 0.0 or piece_size.y <= 0.0:
			continue
		var tex_rect := TextureRect.new()
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = REGIONS[i]
		atlas.filter_clip = true
		tex_rect.texture = atlas
		tex_rect.position = layout[i][0]
		tex_rect.size = piece_size
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tex_rect.use_parent_material = true
		add_child(tex_rect)
		_pieces.append(tex_rect)


func _build_cooldown_label(slot_width: float, slot_height: float) -> void:
	_cooldown_label = Label.new()
	_cooldown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cooldown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_cooldown_label.size = Vector2(slot_width, slot_height)
	_cooldown_label.add_theme_font_size_override("font_size", 28)
	_cooldown_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_cooldown_label)


func _build_keybind_label(slot_width: float, slot_height: float) -> void:
	_keybind_label = Label.new()
	_keybind_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_keybind_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_keybind_label.position = Vector2(26.0, -5.0)
	_keybind_label.size = Vector2(slot_width, slot_height - 8.0)
	_keybind_label.add_theme_font_size_override("font_size", 30)
	_keybind_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_keybind_label)


func _build_icon(slot_width: float, slot_height: float) -> void:
	_icon_rect = TextureRect.new()
	var icon_size := 64.0
	_icon_rect.position = Vector2((slot_width - icon_size) / 2.0, (slot_height - icon_size) / 2.0)
	_icon_rect.size = Vector2(icon_size, icon_size)
	_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon_rect.use_parent_material = true
	add_child(_icon_rect)


func set_icon(texture: Texture2D) -> void:
	_icon_rect.texture = texture


func _get_texture() -> Texture2D:
	if _variant == Variant.BLUE:
		return BLUE_PRESSED if _pressed else BLUE_REGULAR
	else:
		return RED_PRESSED if _pressed else RED_REGULAR


func set_pressed(value: bool) -> void:
	if _pressed == value:
		return
	_pressed = value
	var tex := _get_texture()
	for piece in _pieces:
		(piece.texture as AtlasTexture).atlas = tex

	var content_scale := Vector2(1.08, 0.92) if _pressed else Vector2.ONE
	var y_offset := 4.0 if _pressed else 0.0

	_icon_rect.pivot_offset = _icon_rect.size / 2.0
	_icon_rect.scale = content_scale
	_icon_rect.position.y = (size.y - _icon_rect.size.y) / 2.0 + y_offset

	_cooldown_label.pivot_offset = _cooldown_label.size / 2.0
	_cooldown_label.scale = content_scale
	_cooldown_label.position.y = y_offset

	_keybind_label.pivot_offset = _keybind_label.size / 2.0
	_keybind_label.scale = content_scale
	_keybind_label.position.y = y_offset


func set_desaturated(value: bool) -> void:
	if _desaturated == value:
		return
	_desaturated = value
	_shader_material.set_shader_parameter("saturation", 0.3 if _desaturated else 1.0)


func set_cooldown_text(text: String) -> void:
	_cooldown_label.text = text


func set_keybind_text(text: String) -> void:
	_keybind_label.text = text
