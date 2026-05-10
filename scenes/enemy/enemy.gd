extends Character
class_name Enemy

const DEFAULT_BEHAVIOR := preload("res://scenes/enemy/behaviors/chaser.tres")

@export var enemy_data: EnemyData
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

var sprite: AnimatedSprite2D
var behavior: EnemyBehavior
var behavior_state: Dictionary = {}  # per-enemy scratch space for the behavior
var _health_bar: StatusBar
var _hit_scale_tween: Tween
var _hit_flash_tween: Tween


func _ready() -> void:
	# Match the nav agent's footprint to the actual body so path-postprocessing
	# (EDGECENTERED) routes far enough off walls that the body doesn't clip in.
	# setup() runs before add_child, so @onready nav_agent isn't valid there —
	# _ready fires after add_child, when enemy_data is already set.
	if enemy_data:
		nav_agent.radius = enemy_data.collision_radius


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

	if (max_health > 1 and health > 0):
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
	if behavior:
		behavior.tick(self, delta)
	velocity = behavior.compute_velocity(self, delta) if behavior else Vector2.ZERO
	_update_animation()
	var requested_velocity := velocity
	move_and_slide()
	if behavior:
		for i in range(get_slide_collision_count()):
			behavior.on_collision(self, get_slide_collision(i))
	# Anti-stick: if move_and_slide barely produced any motion (catching on a
	# tile corner, wedged in a concave pocket), redirect the requested velocity
	# along the wall at full speed and slide again. Threshold = half of expected
	# per-frame motion, which fires when we're pushing steeper than ~60° into
	# a wall — normal wall-sliding stays untouched.
	if requested_velocity.length_squared() > 0.0 and \
			get_last_motion().length() < requested_velocity.length() * delta * 0.5:
		_slide_along_obstacle(requested_velocity)


# Set the nav goal and return a unit vector toward the next path waypoint.
# Returns Vector2.ZERO when the path is finished (arrived / unreachable) — the
# caller should treat that as "stop." Behaviors call this instead of
# normalizing (target - position) themselves so navigation routes around
# obstacles baked into the world's NavigationPolygon (see world.tscn).
func nav_direction_to(world_pos: Vector2) -> Vector2:
	nav_agent.target_position = world_pos
	if nav_agent.is_navigation_finished():
		return Vector2.ZERO
	var next_pos := nav_agent.get_next_path_position()
	var to_next := next_pos - global_position
	if to_next.length_squared() < 0.001:
		var direct := world_pos - global_position
		return direct.normalized() if direct.length_squared() > 0.0 else Vector2.ZERO
	return to_next.normalized()


func _slide_along_obstacle(desired_velocity: Vector2) -> void:
	# Move at full speed *parallel* to the wall instead of leaving the slide to
	# move_and_slide(). Letting the physics step slide a goal-pointing velocity
	# produces almost no motion when the incidence is steep — slide-into-wall
	# twice per frame for no benefit.
	#
	# Strategy: Vector2.slide(normal) removes the wall-perpendicular component
	# from the desired velocity, leaving the tangential component pointing the
	# right way (toward the goal). Normalising and scaling back to the full
	# speed gives us proper sliding at the agent's intended speed.
	if get_slide_collision_count() == 0:
		return
	var avg_normal := Vector2.ZERO
	for i in range(get_slide_collision_count()):
		avg_normal += get_slide_collision(i).get_normal()
	if avg_normal.length_squared() == 0.0:
		return
	avg_normal = avg_normal.normalized()

	var slid := desired_velocity.slide(avg_normal)
	if slid.length_squared() < 1.0:
		# Corner pinch — desired velocity is nearly anti-parallel to the
		# average normal, so projecting it onto the wall plane vanishes. The
		# only useful direction is *along* one of the walls' tangents. Use the
		# path lookahead (which points past the corner along the nav route) to
		# pick which side; if the lookahead is also perpendicular, just bail
		# this frame instead of vibrating.
		var path_dir := _path_lookahead_direction()
		if path_dir.length_squared() < 1.0:
			return
		var tangent := Vector2(-avg_normal.y, avg_normal.x)
		var dot := tangent.dot(path_dir)
		if absf(dot) < 0.1:
			return  # both tangents equally bad — let the path recompute
		if dot < 0.0:
			tangent = -tangent
		slid = tangent * desired_velocity.length()

	velocity = slid.normalized() * desired_velocity.length()
	move_and_slide()


func _path_lookahead_direction() -> Vector2:
	var path := nav_agent.get_current_navigation_path()
	if path.size() == 0:
		if target != null and is_instance_valid(target):
			return target.global_position - global_position
		return velocity
	var idx := nav_agent.get_current_navigation_path_index()
	var look_idx: int = mini(idx + 2, path.size() - 1)
	return path[look_idx] - global_position


func _update_animation() -> void:
	if not sprite or is_attacking:
		return

	var face_dir_x := 0.0
	if target != null and is_instance_valid(target):
		face_dir_x = target.global_position.x - global_position.x
	elif velocity.x != 0.0:
		face_dir_x = velocity.x
	if face_dir_x < 0.0:
		sprite.flip_h = true
	elif face_dir_x > 0.0:
		sprite.flip_h = false

	if velocity == Vector2.ZERO:
		if sprite.animation != &"idle":
			sprite.play("idle")
	else:
		if sprite.animation != &"run":
			sprite.play("run")


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

	var idle_tex: Texture2D = enemy_data.idle_texture_override if enemy_data.idle_texture_override else load(base_path + "idle.png") as Texture2D
	var attack_tex: Texture2D = enemy_data.attack_texture_override if enemy_data.attack_texture_override else load(base_path + "attack.png") as Texture2D
	var run_tex: Texture2D = enemy_data.run_texture_override if enemy_data.run_texture_override else load(base_path + "run.png") as Texture2D

	_add_animation(frames, "idle", idle_tex, enemy_data.idle_frames)
	_add_animation(frames, "attack", attack_tex, enemy_data.attack_frames, false)
	_add_animation(frames, "run", run_tex, enemy_data.run_frames)

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
