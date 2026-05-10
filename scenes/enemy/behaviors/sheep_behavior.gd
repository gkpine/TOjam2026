class_name SheepBehavior
extends EnemyBehavior

# Sheep movement: stay near their shepherd, mill around when in range, run
# back if they fall behind. The owning shepherd is stored in
# behavior_state["shepherd"] by ShepherdBehavior._spawn_minion when the sheep
# is created. If the shepherd dies (or was never set) the sheep just wanders
# around its current position.
#
# Per-enemy state (enemy.behavior_state):
#   "shepherd"      : Enemy    — owner shepherd, set by ShepherdBehavior
#   "wander_mode"   : int      — MODE_PAUSED | MODE_WALKING
#   "wander_timer"  : float    — seconds left in the current mode
#   "wander_target" : Vector2  — current point the sheep is walking toward
#                                (only meaningful in MODE_WALKING)

const MODE_PAUSED := 0
const MODE_WALKING := 1

@export var follow_distance: float = 240.0      # outside → run to shepherd
@export var wander_radius: float = 110.0        # wander targets stay within this of the shepherd
@export var follow_speed_multiplier: float = 1.0
@export var wander_speed_multiplier: float = 0.5
@export var wander_pause_min: float = 1.0
@export var wander_pause_max: float = 2.5
@export var wander_walk_min: float = 0.8
@export var wander_walk_max: float = 1.8
@export var arrived_threshold: float = 8.0      # close-enough distance to a wander target


func compute_velocity(enemy: Enemy, delta: float) -> Vector2:
	var s := enemy.behavior_state
	if not s.has("wander_mode"):
		s["wander_mode"] = MODE_PAUSED
		s["wander_timer"] = randf_range(wander_pause_min, wander_pause_max)
		s["wander_target"] = enemy.global_position

	var shepherd: Enemy = s.get("shepherd", null) as Enemy
	var anchor: Vector2 = enemy.global_position
	var has_live_shepherd := shepherd != null and is_instance_valid(shepherd)
	if has_live_shepherd:
		anchor = shepherd.global_position
		var dist_to_shepherd := enemy.global_position.distance_to(anchor)
		if dist_to_shepherd > follow_distance:
			# Too far from the shepherd — sprint to catch up. Skip the wander
			# state machine entirely so we don't pause partway home.
			var follow_dir := enemy.nav_direction_to(anchor)
			if follow_dir == Vector2.ZERO:
				return Vector2.ZERO
			return follow_dir * enemy.movement_speed * follow_speed_multiplier

	return _wander(enemy, delta, anchor)


func _wander(enemy: Enemy, delta: float, anchor: Vector2) -> Vector2:
	var s := enemy.behavior_state
	s["wander_timer"] = (s["wander_timer"] as float) - delta
	var mode: int = s["wander_mode"] as int

	# Mode flip: paused → pick a new target and start walking; walking → pause.
	if (s["wander_timer"] as float) <= 0.0:
		if mode == MODE_PAUSED:
			var angle := randf() * TAU
			var radius := sqrt(randf()) * wander_radius  # uniform within disc
			s["wander_target"] = anchor + Vector2.from_angle(angle) * radius
			s["wander_mode"] = MODE_WALKING
			s["wander_timer"] = randf_range(wander_walk_min, wander_walk_max)
			mode = MODE_WALKING
		else:
			s["wander_mode"] = MODE_PAUSED
			s["wander_timer"] = randf_range(wander_pause_min, wander_pause_max)
			mode = MODE_PAUSED

	if mode == MODE_PAUSED:
		return Vector2.ZERO

	var target_pos: Vector2 = s["wander_target"]
	if enemy.global_position.distance_squared_to(target_pos) <= arrived_threshold * arrived_threshold:
		# Arrived early — switch to a short pause instead of grinding into the spot.
		s["wander_mode"] = MODE_PAUSED
		s["wander_timer"] = randf_range(wander_pause_min, wander_pause_max)
		return Vector2.ZERO

	var dir := enemy.nav_direction_to(target_pos)
	if dir == Vector2.ZERO:
		return Vector2.ZERO
	return dir * enemy.movement_speed * wander_speed_multiplier
