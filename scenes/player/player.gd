extends Character
class_name Player

const FRAME_SIZE := 192

var sprite: AnimatedSprite2D
var player_index: int = 0
var player_color: Color = Color.WHITE


func setup(index: int, color: Color) -> void:
	player_index = index
	player_color = color
	sprite = $AnimatedSprite2D
	sprite.sprite_frames = _build_sprite_frames()
	sprite.play("idle")


func _physics_process(_delta: float) -> void:
	var direction := InputManager.get_movement_vector(player_index)
	velocity = direction * movement_speed
	move_and_slide()
	GameState.update_player_position(player_index, global_position)

	if velocity != Vector2.ZERO:
		if sprite.animation != &"run":
			sprite.play("run")
		if velocity.x < 0:
			sprite.flip_h = true
		elif velocity.x > 0:
			sprite.flip_h = false
	else:
		if sprite.animation != &"idle":
			sprite.play("idle")


func _build_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	var n := player_index + 1
	var base_path := "res://assets/players/player%d/player_%d_" % [n, n]

	_add_animation(frames, "idle", load(base_path + "idle.png"), 8)
	_add_animation(frames, "run", load(base_path + "run.png"), 6)

	frames.remove_animation("default")
	return frames


func _add_animation(frames: SpriteFrames, anim_name: String, sheet: Texture2D, frame_count: int) -> void:
	frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, 10)
	frames.set_animation_loop(anim_name, true)
	for i in range(frame_count):
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(i * FRAME_SIZE, 0, FRAME_SIZE, FRAME_SIZE)
		frames.add_frame(anim_name, atlas)
