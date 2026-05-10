extends Control

# Funky 4-quadrant menu backdrop:
#   - One ColorRect per quadrant runs the psychedelic plasma shader with a
#     unique seed, so the four panes feel like they belong to different
#     trippy worlds (matches the in-game split-screen layout).
#   - Each quadrant gets a handful of enemy sprites that drift, rotate,
#     pulse, and hue-cycle. Sprites wrap inside their own quadrant so the
#     split aesthetic stays clean.
#   - Thin separator lines mirror scenes/game/game.gd's 4-player layout.
#
# Per-floater state lives in a Dictionary instead of an inner class — the
# rest of the codebase has no inner classes, and Dictionary keeps loop
# variables explicitly typed (CLAUDE.md: warnings are errors, no := on
# Variant-returning calls).

const ENEMY_TYPE_PATHS: Array[String] = [
	"res://scenes/enemy/types/bear.tres",
	"res://scenes/enemy/types/gnoll.tres",
	"res://scenes/enemy/types/gnome.tres",
	"res://scenes/enemy/types/lizard.tres",
	"res://scenes/enemy/types/minotaur.tres",
	"res://scenes/enemy/types/panda.tres",
	"res://scenes/enemy/types/sheep.tres",
	"res://scenes/enemy/types/skull.tres",
	"res://scenes/enemy/types/snake.tres",
	"res://scenes/enemy/types/spider.tres",
	"res://scenes/enemy/types/thief.tres",
	"res://scenes/enemy/types/troll.tres",
	"res://scenes/enemy/types/turtle.tres",
]

const SPRITES_PER_QUADRANT: int = 6
const SEPARATOR_WIDTH: float = 2.0
const SEPARATOR_COLOR: Color = Color(0.08, 0.08, 0.1, 0.85)
# Matches project.godot's environment/defaults/default_clear_color so the
# quadrants read as the same teal the menu used to sit on top of, just
# now subdivided 2x2 by the separator lines.
const QUADRANT_FILL: Color = Color(0.2784314, 0.67058825, 0.6627451, 1.0)

var _floaters: Array[Dictionary] = []
var _quadrant_rects: Array[Rect2] = []
@onready var _sprites_root: Node2D = $Sprites


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_rebuild)
	_rebuild()


# Rebuild from scratch on resize. The menu is full-rect so this fires at
# startup once layout settles, and again if the OS window changes size.
func _rebuild() -> void:
	for child in _sprites_root.get_children():
		child.queue_free()
	for child in get_children():
		if child is ColorRect:
			child.queue_free()
	_floaters.clear()
	_quadrant_rects.clear()

	var rect_size: Vector2 = size
	if rect_size.x <= 0.0 or rect_size.y <= 0.0:
		return

	var half_w: float = rect_size.x / 2.0
	var half_h: float = rect_size.y / 2.0
	_quadrant_rects = [
		Rect2(0.0, 0.0, half_w, half_h),
		Rect2(half_w, 0.0, half_w, half_h),
		Rect2(0.0, half_h, half_w, half_h),
		Rect2(half_w, half_h, half_w, half_h),
	]

	# Backgrounds first so they render behind the Sprites layer.
	for i in range(_quadrant_rects.size()):
		_build_quadrant_background(i, _quadrant_rects[i])

	# Move every ColorRect we just added to the front of the child list so
	# they sit *behind* the existing Sprites Node2D in draw order.
	var bg_count: int = 0
	for child in get_children():
		if child is ColorRect:
			move_child(child, bg_count)
			bg_count += 1

	for i in range(_quadrant_rects.size()):
		_populate_quadrant(i, _quadrant_rects[i])

	_add_separators(rect_size)


func _build_quadrant_background(_seed_index: int, rect: Rect2) -> void:
	var bg := ColorRect.new()
	bg.color = QUADRANT_FILL
	bg.size = rect.size
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	bg.position = rect.position


func _populate_quadrant(seed_index: int, rect: Rect2) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("menubg-floaters-" + str(seed_index))
	for _n in range(SPRITES_PER_QUADRANT):
		var path: String = ENEMY_TYPE_PATHS[rng.randi() % ENEMY_TYPE_PATHS.size()]
		var data: EnemyData = load(path) as EnemyData
		if data == null:
			continue
		var anim: AnimatedSprite2D = _make_idle_sprite(data)
		if anim == null:
			continue

		# Normalise on-screen size against frame_size so the troll (384px)
		# doesn't dwarf the sheep (128px). target_px is the intended visible
		# height; the actual sprite will pulse around it.
		var target_px: float = rng.randf_range(90.0, 170.0)
		var scale_base: float = target_px / float(data.frame_size)

		var floater: Dictionary = {
			"node": anim,
			"rect": rect,
			"velocity": Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(20.0, 55.0),
			"rotation_speed": rng.randf_range(-1.4, 1.4),
			"hue_speed": rng.randf_range(0.10, 0.35),
			"hue_phase": rng.randf(),
			"scale_base": scale_base,
			"scale_amp": rng.randf_range(0.06, 0.14),
			"scale_phase": rng.randf() * TAU,
			"scale_speed": rng.randf_range(0.7, 1.8),
		}

		# Match the codebase convention (CLAUDE.md "Cast UI" gotcha):
		# build visual content (sprite_frames, scale) before add_child,
		# set position after.
		anim.scale = Vector2.ONE * scale_base
		_sprites_root.add_child(anim)
		anim.position = rect.position + Vector2(rng.randf() * rect.size.x, rng.randf() * rect.size.y)
		anim.play("idle")
		# Desync the animation cycles so all six sprites in a quadrant don't
		# breathe in unison.
		anim.frame = rng.randi() % maxi(data.idle_frames, 1)
		_floaters.append(floater)


func _make_idle_sprite(data: EnemyData) -> AnimatedSprite2D:
	# Mirrors enemy.gd's _build_sprite_frames for the idle animation only.
	# We skip attack/run because the menu sprites never enter combat.
	var idle_tex: Texture2D = data.idle_texture_override
	if idle_tex == null:
		var path: String = "res://assets/enemies/%s/%s_idle.png" % [data.enemy_name, data.enemy_name]
		idle_tex = load(path) as Texture2D
	if idle_tex == null:
		return null

	var sprite := AnimatedSprite2D.new()
	var frames := SpriteFrames.new()
	frames.add_animation(&"idle")
	frames.set_animation_speed(&"idle", 10)
	frames.set_animation_loop(&"idle", true)
	for i in range(data.idle_frames):
		var atlas := AtlasTexture.new()
		atlas.atlas = idle_tex
		atlas.region = Rect2(i * data.frame_size, 0, data.frame_size, data.frame_size)
		frames.add_frame(&"idle", atlas)
	frames.remove_animation(&"default")
	sprite.sprite_frames = frames
	return sprite


func _add_separators(rect_size: Vector2) -> void:
	var hw: float = SEPARATOR_WIDTH / 2.0
	_add_line(Vector2(rect_size.x / 2.0 - hw, 0.0), Vector2(SEPARATOR_WIDTH, rect_size.y))
	_add_line(Vector2(0.0, rect_size.y / 2.0 - hw), Vector2(rect_size.x, SEPARATOR_WIDTH))


func _add_line(line_pos: Vector2, line_size: Vector2) -> void:
	var line := ColorRect.new()
	line.position = line_pos
	line.size = line_size
	line.color = SEPARATOR_COLOR
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(line)


func _process(delta: float) -> void:
	var t: float = Time.get_ticks_msec() / 1000.0
	for f: Dictionary in _floaters:
		var node: AnimatedSprite2D = f["node"]
		if not is_instance_valid(node):
			continue
		var rect: Rect2 = f["rect"]
		var velocity: Vector2 = f["velocity"]
		var pos: Vector2 = node.position + velocity * delta

		# Wrap inside the floater's own quadrant so sprites never bleed
		# across the split-screen seams.
		if pos.x < rect.position.x:
			pos.x += rect.size.x
		elif pos.x > rect.position.x + rect.size.x:
			pos.x -= rect.size.x
		if pos.y < rect.position.y:
			pos.y += rect.size.y
		elif pos.y > rect.position.y + rect.size.y:
			pos.y -= rect.size.y
		node.position = pos

		node.rotation += float(f["rotation_speed"]) * delta

		var scale_base: float = f["scale_base"]
		var scale_amp: float = f["scale_amp"]
		var scale_phase: float = f["scale_phase"]
		var scale_speed: float = f["scale_speed"]
		var pulse: float = 1.0 + scale_amp * sin(t * scale_speed + scale_phase)
		node.scale = Vector2.ONE * (scale_base * pulse)

		var hue_speed: float = f["hue_speed"]
		var hue_phase: float = f["hue_phase"]
		var hue: float = fmod(t * hue_speed + hue_phase, 1.0)
		# Saturation < 1 keeps a bit of the original sprite art readable
		# under the tint; alpha < 1 lets the plasma bleed through.
		node.modulate = Color.from_hsv(hue, 0.55, 1.0, 0.9)
