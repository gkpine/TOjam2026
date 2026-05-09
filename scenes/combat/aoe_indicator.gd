class_name AoeIndicator
extends Sprite2D

# Renders the AoE telegraph as a circle by generating an ImageTexture at
# runtime. Caller MUST call setup() before add_child — the texture and other
# visual properties have to be configured before the node enters the tree
# for it to render reliably.

@export var indicator_radius: float = 100.0
@export var fill_color: Color = Color(1.0, 0.2, 0.2, 0.35)
@export var border_color: Color = Color(1.0, 0.2, 0.2, 0.95)
@export var border_thickness: float = 4.0


func setup() -> void:
	texture = _make_circle_texture()
	z_index = 5


func _make_circle_texture() -> Texture2D:
	var size := int(ceil(indicator_radius * 2.0)) + 2
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size / 2.0, size / 2.0)
	for y in range(size):
		for x in range(size):
			var dist := Vector2(x, y).distance_to(center)
			if dist < indicator_radius - border_thickness:
				img.set_pixel(x, y, fill_color)
			elif dist < indicator_radius:
				img.set_pixel(x, y, border_color)
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(img)
