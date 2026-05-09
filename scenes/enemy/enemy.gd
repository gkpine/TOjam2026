extends Character
class_name Enemy

const DEFAULT_BEHAVIOR := preload("res://scenes/enemy/behaviors/chaser.tres")

@export var enemy_data: EnemyData

var sprite: AnimatedSprite2D
var behavior: EnemyBehavior
var behavior_state: Dictionary = {}  # per-enemy scratch space for the behavior
var _health_bar: StatusBar
var _hit_scale_tween: Tween
var _hit_flash_tween: Tween


func setup(data: EnemyData) -> void:
	enemy_data = data
	_apply_stats()
	behavior = enemy_data.behavior if enemy_data.behavior else DEFAULT_BEHAVIOR
	sprite = $AnimatedSprite2D
	sprite.sprite_frames = _build_sprite_frames()
	sprite.play("idle")
	$CollisionShape2D.shape = CircleShape2D.new()
	$CollisionShape2D.shape.radius = enemy_data.collision_radius
	sprite.offset.y = enemy_data.collision_radius - (enemy_data.visible_sprite_height / 6.0)
	var reticle := preload("res://scenes/combat/targeting_reticle.tscn").instantiate()
	add_child(reticle)
	reticle.setup(enemy_data.collision_radius)

	_health_bar = StatusBar.new()
	add_child(_health_bar)
	_health_bar.setup(
		preload("res://Tiny Swords (Free Pack)/UI Elements/UI Elements/Bars/SmallBar_Base.png"),
		preload("res://Tiny Swords (Free Pack)/UI Elements/UI Elements/Bars/SmallBar_Fill.png"),
		1
	)
	_health_bar.set_fill_color(Color(1.0, 0.2, 0.2))
	_health_bar.position.x = -_health_bar.get_bar_width() / 2.0
	_health_bar.position.y = sprite.offset.y - (enemy_data.visible_sprite_height / 2)
	health_changed.connect(_on_health_changed)


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


func _physics_process(delta: float) -> void:
	if is_casting:
		velocity = Vector2.ZERO
		_update_animation()
		move_and_slide()
		return
	velocity = behavior.compute_velocity(self, delta) if behavior else Vector2.ZERO
	_update_animation()
	move_and_slide()
	if behavior:
		for i in range(get_slide_collision_count()):
			behavior.on_collision(self, get_slide_collision(i))


func _update_animation() -> void:
	if not sprite or is_attacking:
		return
	if velocity == Vector2.ZERO:
		if sprite.animation != &"idle":
			sprite.play("idle")
	else:
		if sprite.animation != &"run":
			sprite.play("run")
		sprite.flip_h = velocity.x < 0


func _apply_stats() -> void:
	health = enemy_data.health
	max_health = enemy_data.max_health if enemy_data.max_health > 0.0 else enemy_data.health
	base_damage = enemy_data.base_damage
	strength = enemy_data.strength
	auto_attack_enabled = enemy_data.auto_attack_enabled
	auto_attack_per_second = enemy_data.auto_attack_per_second
	auto_attack_delay = enemy_data.auto_attack_delay
	movement_speed = enemy_data.movement_speed
	target_range_px = enemy_data.target_range_px
	auto_attack_range_px = enemy_data.auto_attack_range_px
	base_health_regen_per_second = enemy_data.base_health_regen_per_second
	in_combat_health_regen_multiplier = enemy_data.in_combat_health_regen_multiplier
	moving_hp_regen_multiplier = enemy_data.moving_hp_regen_multiplier


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


func take_damage(amount: float, damage_type: String = "auto_attack", attacker: Character = null) -> void:
	super.take_damage(amount, damage_type, attacker)
	_play_hit_reaction()


func _play_hit_reaction() -> void:
	if not is_instance_valid(sprite):
		return

	if _hit_scale_tween and _hit_scale_tween.is_valid():
		_hit_scale_tween.kill()
	if _hit_flash_tween and _hit_flash_tween.is_valid():
		_hit_flash_tween.kill()

	sprite.scale = Vector2.ONE
	sprite.modulate = Color.WHITE

	_hit_scale_tween = create_tween()
	_hit_scale_tween.tween_property(sprite, "scale", Vector2(1.2, 0.85), 0.08) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_hit_scale_tween.tween_property(sprite, "scale", Vector2(0.95, 1.05), 0.12) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	_hit_scale_tween.tween_property(sprite, "scale", Vector2.ONE, 0.1) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)

	_hit_flash_tween = create_tween()
	_hit_flash_tween.tween_property(sprite, "modulate", Color(1.0, 0.7, 0.7), 0.15)
	_hit_flash_tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)


func _on_health_changed(_amount: int, _world_pos: Vector2, _change_type: String) -> void:
	if _health_bar and is_instance_valid(_health_bar):
		_health_bar.update_value(health, get_effective_stat("max_health"))


func _add_animation(frames: SpriteFrames, anim_name: String, sheet: Texture2D, frame_count: int, looping: bool = true) -> void:
	frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, 10)
	frames.set_animation_loop(anim_name, looping)
	for i in range(frame_count):
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(i * enemy_data.frame_size, 0, enemy_data.frame_size, enemy_data.frame_size)
		frames.add_frame(anim_name, atlas)
