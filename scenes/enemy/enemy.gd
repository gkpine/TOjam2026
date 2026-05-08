extends Character
class_name Enemy

@export var enemy_data: EnemyData

var sprite: AnimatedSprite2D


func setup(data: EnemyData) -> void:
	enemy_data = data
	_apply_stats()
	sprite = $AnimatedSprite2D
	sprite.sprite_frames = _build_sprite_frames()
	sprite.play("idle")


func _apply_stats() -> void:
	health = enemy_data.health
	max_health = enemy_data.health
	base_damage = enemy_data.base_damage
	strength = enemy_data.strength
	auto_attack_per_second = enemy_data.auto_attack_per_second
	movement_speed = enemy_data.movement_speed
	target_range_px = enemy_data.target_range_px
	auto_attack_range_px = enemy_data.auto_attack_range_px


func _build_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	var base_path := "res://assets/enemies/%s/%s_" % [enemy_data.enemy_name, enemy_data.enemy_name]

	_add_animation(frames, "idle", load(base_path + "idle.png"), enemy_data.idle_frames)
	_add_animation(frames, "attack", load(base_path + "attack.png"), enemy_data.attack_frames)
	_add_animation(frames, "run", load(base_path + "run.png"), enemy_data.run_frames)

	frames.remove_animation("default")
	return frames


func _add_animation(frames: SpriteFrames, anim_name: String, sheet: Texture2D, frame_count: int) -> void:
	frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, 10)
	frames.set_animation_loop(anim_name, true)
	for i in range(frame_count):
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(i * enemy_data.frame_size, 0, enemy_data.frame_size, enemy_data.frame_size)
		frames.add_frame(anim_name, atlas)
