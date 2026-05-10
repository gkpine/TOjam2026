class_name MinionProjectile
extends Area2D

# Straight-line projectile fired by ShepherdBehavior. Configure visuals and
# combat data via setup() BEFORE add_child (per the runtime-spawned-visuals
# gotcha in CLAUDE.md). Travels until it hits a body or max_lifetime expires.
#
# Collision setup: layer 0 (invisible to anything), mask = walls (1) + player
# (4) so we hit either but enemies don't react to the projectile flying past.

var direction: Vector2 = Vector2.RIGHT
var speed: float = 500.0
var damage: float = 12.0
var attacker: Character = null
var max_lifetime: float = 2.0
var _life_elapsed: float = 0.0
var _consumed: bool = false


func setup(dir: Vector2, spd: float, dmg: float, lifetime: float,
		atk: Character, sprite_texture: Texture2D, sprite_frame_size: int,
		visible_height: int, target_render_height: float = 32.0) -> void:
	direction = dir.normalized() if dir.length_squared() > 0.0 else Vector2.RIGHT
	speed = spd
	damage = dmg
	max_lifetime = lifetime
	attacker = atk

	collision_layer = 0
	collision_mask = 5  # walls (1) + player (4)

	var sprite := Sprite2D.new()
	if sprite_texture != null and sprite_frame_size > 0:
		var atlas := AtlasTexture.new()
		atlas.atlas = sprite_texture
		atlas.region = Rect2(0, 0, sprite_frame_size, sprite_frame_size)
		sprite.texture = atlas
		var height_for_scale: float = float(visible_height) if visible_height > 0 else float(sprite_frame_size)
		var s: float = target_render_height / height_for_scale
		sprite.scale = Vector2(s, s)
	else:
		# Fallback so a missing texture is still visible/debuggable.
		var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		sprite.texture = ImageTexture.create_from_image(img)
	add_child(sprite)

	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 12.0
	collision.shape = shape
	add_child(collision)


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if _consumed:
		return
	_life_elapsed += delta
	if _life_elapsed >= max_lifetime:
		queue_free()
		return
	global_position += direction * speed * delta


func _on_body_entered(body: Node) -> void:
	if _consumed:
		return
	_consumed = true
	if body is Character:
		(body as Character).take_damage(damage, "minion_throw", attacker)
	queue_free()
