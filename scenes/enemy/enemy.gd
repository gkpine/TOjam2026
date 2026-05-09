extends Character
class_name Enemy

@export var enemy_data: EnemyData

var sprite: AnimatedSprite2D
var stop_distance: float = 60.0


func setup(data: EnemyData) -> void:
	enemy_data = data
	_apply_stats()
	sprite = $AnimatedSprite2D
	sprite.sprite_frames = _build_sprite_frames()
	sprite.play("idle")
	$CollisionShape2D.shape = CircleShape2D.new()
	$CollisionShape2D.shape.radius = enemy_data.collision_radius
	sprite.offset.y = enemy_data.collision_radius - (enemy_data.frame_size / 6.0);
	var reticle := preload("res://scenes/combat/targeting_reticle.tscn").instantiate()
	add_child(reticle)


func _process(delta: float) -> void:
	super(delta)
	_acquire_target()


func _acquire_target() -> void:
	if target != null and is_instance_valid(target):
		return
	target = null
	var world := get_parent()
	if world == null:
		return
	var player = world.get("player")
	if player != null and is_instance_valid(player):
		var dist := global_position.distance_to(player.global_position)
		if dist <= target_range_px:
			target = player


func _physics_process(_delta: float) -> void:
	if target == null or not is_instance_valid(target):
		target = null
		velocity = Vector2.ZERO
		if sprite and not is_attacking and sprite.animation != &"idle":
			sprite.play("idle")
		return

	var dist := global_position.distance_to(target.global_position)
	if dist <= stop_distance:
		velocity = Vector2.ZERO
		if sprite and not is_attacking and sprite.animation != &"idle":
			sprite.play("idle")
	else:
		var direction := (target.global_position - global_position).normalized()
		velocity = direction * movement_speed
		if sprite and not is_attacking:
			if sprite.animation != &"run":
				sprite.play("run")
			sprite.flip_h = velocity.x < 0
	move_and_slide()


func _apply_stats() -> void:
	health = enemy_data.health
	max_health = enemy_data.max_health if enemy_data.max_health > 0.0 else enemy_data.health
	base_damage = enemy_data.base_damage
	strength = enemy_data.strength
	auto_attack_per_second = enemy_data.auto_attack_per_second
	auto_attack_delay = enemy_data.auto_attack_delay
	movement_speed = enemy_data.movement_speed
	target_range_px = enemy_data.target_range_px
	auto_attack_range_px = enemy_data.auto_attack_range_px


func _build_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	var base_path := "res://assets/enemies/%s/%s_" % [enemy_data.enemy_name, enemy_data.enemy_name]

	_add_animation(frames, "idle", load(base_path + "idle.png"), enemy_data.idle_frames)
	_add_animation(frames, "attack", load(base_path + "attack.png"), enemy_data.attack_frames, false)
	_add_animation(frames, "run", load(base_path + "run.png"), enemy_data.run_frames)

	frames.remove_animation("default")
	return frames


func play_attack_animation(anim_name: StringName = &"attack") -> void:
	is_attacking = true
	sprite.play(anim_name)
	await sprite.animation_finished
	is_attacking = false


func _add_animation(frames: SpriteFrames, anim_name: String, sheet: Texture2D, frame_count: int, looping: bool = true) -> void:
	frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, 10)
	frames.set_animation_loop(anim_name, looping)
	for i in range(frame_count):
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(i * enemy_data.frame_size, 0, enemy_data.frame_size, enemy_data.frame_size)
		frames.add_frame(anim_name, atlas)
