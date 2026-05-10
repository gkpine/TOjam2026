class_name ShepherdBehavior
extends EnemyBehavior

# Spawns minions on the ground and throws them as damaging projectiles.
# Movement (compute_velocity) and actions (tick) are split: tick decides what
# the shepherd should be doing this frame, compute_velocity steers accordingly.
#
# num_sheep = 0  → conjure-and-throw: no minions on the ground; throws spawn
#                  from the shepherd's own position on cooldown.
# num_sheep > 0  → maintain that many minion enemies nearby. When throw is
#                  ready, walks to the nearest one, frees it, and fires the
#                  projectile from where the minion stood.
#
# Per-enemy state (enemy.behavior_state):
#   "phase"       : int    — PHASE_CHASE | PHASE_APPROACH_MINION
#   "spawn_cd"    : float  — seconds until next minion spawn
#   "throw_cd"    : float  — seconds until next throw
#   "minions"     : Array  — alive minions this shepherd is responsible for
#   "grab_target" : Enemy  — minion we're walking toward to throw

const MINION_PROJECTILE := preload("res://scenes/enemy/minion_projectile.gd")

const PHASE_CHASE := 0
const PHASE_APPROACH_MINION := 1

@export var num_sheep: int = 5
@export var minion_data: EnemyData
@export var spawn_cooldown: float = 4.0
@export var spawn_offset_radius: float = 70.0
@export var throw_cooldown: float = 3.0
@export var initial_throw_delay: float = 2.5
@export var grab_distance: float = 40.0
@export var stop_distance: float = 220.0
@export var projectile_speed: float = 520.0
@export var projectile_damage: float = 14.0
@export var projectile_lifetime: float = 2.0

func tick(enemy: Enemy, delta: float) -> void:
	var s := enemy.behavior_state
	if not s.has("phase"):
		s["phase"] = PHASE_CHASE
		s["spawn_cd"] = spawn_cooldown
		s["throw_cd"] = initial_throw_delay
		s["minions"] = [] as Array[Enemy]
		s["grab_target"] = null
		# Seed the flock so the shepherd shows up to the fight already armed.
		# (Done here, not in _ready, because EnemyBehavior is a Resource —
		# Godot never calls _ready on it, and there's no single owning enemy.)
		var initial_flock: Array[Enemy] = s["minions"]
		for i in range(num_sheep):
			_spawn_minion(enemy, initial_flock)

	s["spawn_cd"] = maxf((s["spawn_cd"] as float) - delta, 0.0)
	s["throw_cd"] = maxf((s["throw_cd"] as float) - delta, 0.0)

	# Drop dead/freed minions from tracking. The player can kill them to deny
	# the shepherd ammo — that's the intended counterplay.
	var minions: Array[Enemy] = s["minions"]
	for i in range(minions.size() - 1, -1, -1):
		if not is_instance_valid(minions[i]):
			minions.remove_at(i)

	if enemy.target == null or not is_instance_valid(enemy.target):
		s["phase"] = PHASE_CHASE
		s["grab_target"] = null
		return

	# Maintain the sheep flock whenever we're under cap, regardless of phase.
	if num_sheep > 0 and minions.size() < num_sheep and (s["spawn_cd"] as float) <= 0.0:
		_spawn_minion(enemy, minions)
		s["spawn_cd"] = spawn_cooldown

	var phase: int = s["phase"]
	match phase:
		PHASE_CHASE:
			if (s["throw_cd"] as float) > 0.0:
				return
			if num_sheep <= 0:
				_fire_projectile(enemy, enemy.global_position)
				s["throw_cd"] = throw_cooldown
				return
			var nearest := _nearest_minion(enemy, minions)
			if nearest != null:
				s["grab_target"] = nearest
				s["phase"] = PHASE_APPROACH_MINION
		PHASE_APPROACH_MINION:
			# Don't `as Enemy` before is_instance_valid — casting a freed object
			# itself throws "Trying to cast a freed object."
			var grab_obj: Object = s["grab_target"]
			if grab_obj == null or not is_instance_valid(grab_obj):
				s["phase"] = PHASE_CHASE
				s["grab_target"] = null
				return
			var grab := grab_obj as Enemy
			if enemy.global_position.distance_to(grab.global_position) <= grab_distance:
				var origin := grab.global_position
				minions.erase(grab)
				grab.queue_free()
				_fire_projectile(enemy, origin)
				s["throw_cd"] = throw_cooldown
				s["grab_target"] = null
				s["phase"] = PHASE_CHASE


func compute_velocity(enemy: Enemy, _delta: float) -> Vector2:
	if enemy.target == null or not is_instance_valid(enemy.target):
		return Vector2.ZERO

	var s := enemy.behavior_state
	var phase: int = (s.get("phase", PHASE_CHASE) as int)

	if phase == PHASE_APPROACH_MINION:
		var grab_obj: Object = s.get("grab_target", null)
		if grab_obj == null or not is_instance_valid(grab_obj):
			return Vector2.ZERO
		var grab := grab_obj as Enemy
		var dist := enemy.global_position.distance_to(grab.global_position)
		if dist <= grab_distance:
			return Vector2.ZERO
		var dir := enemy.nav_direction_to(grab.global_position)
		return dir * enemy.movement_speed if dir != Vector2.ZERO else Vector2.ZERO

	# CHASE: keep at kite distance from the player so the shepherd doesn't
	# turn into a melee pinata while waiting for cooldowns.
	var dist_to_player := enemy.global_position.distance_to(enemy.target.global_position)
	if dist_to_player <= stop_distance:
		return Vector2.ZERO
	var nav_dir := enemy.nav_direction_to(enemy.target.global_position)
	return nav_dir * enemy.movement_speed if nav_dir != Vector2.ZERO else Vector2.ZERO


func _spawn_minion(enemy: Enemy, minions: Array[Enemy]) -> void:
	if minion_data == null:
		return
	var world := enemy.get_parent()
	if world == null or not world.has_method("spawn_enemy_at"):
		return
	var angle := randf() * TAU
	var pos := enemy.global_position + Vector2.from_angle(angle) * spawn_offset_radius
	var minion: Enemy = world.spawn_enemy_at(minion_data, pos)
	if minion != null:
		# Tell the minion who its shepherd is — SheepBehavior reads this from
		# behavior_state to follow / wander around the right enemy.
		minion.behavior_state["shepherd"] = enemy
		minions.append(minion)


func _fire_projectile(enemy: Enemy, origin: Vector2) -> void:
	if enemy.target == null or not is_instance_valid(enemy.target):
		return
	var world := enemy.get_parent()
	if world == null:
		return
	var to_target := enemy.target.global_position - origin
	if to_target.length_squared() < 0.001:
		return
	var projectile: MinionProjectile = MINION_PROJECTILE.new()
	var sprite_tex: Texture2D = null
	var frame_size: int = 0
	var visible_height: int = 0
	if minion_data != null:
		sprite_tex = minion_data.idle_texture_override
		frame_size = minion_data.frame_size
		visible_height = minion_data.visible_sprite_height
	projectile.setup(to_target, projectile_speed, projectile_damage,
			projectile_lifetime, enemy, sprite_tex, frame_size, visible_height)
	world.add_child(projectile)
	projectile.global_position = origin


func _nearest_minion(enemy: Enemy, minions: Array[Enemy]) -> Enemy:
	var best: Enemy = null
	var best_dist := INF
	for m in minions:
		if not is_instance_valid(m):
			continue
		var d := enemy.global_position.distance_to(m.global_position)
		if d < best_dist:
			best_dist = d
			best = m
	return best
