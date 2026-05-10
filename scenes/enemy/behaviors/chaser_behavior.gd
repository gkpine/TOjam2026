class_name ChaserBehavior
extends EnemyBehavior

# Walks toward the target, but with two anti-stick mechanisms:
#
#  1. SLOWDOWN BAND: between (stop_distance + slow_band) and stop_distance, the
#     enemy ramps its speed from full down to zero. This stops the enemy from
#     hitting the player at full speed and starting a "we're both pressing
#     into each other every frame" jitter loop.
#
#  2. SEPARATION FORCE: inside stop_distance, the enemy applies a backoff
#     velocity proportional to how deep the overlap is, scaled by
#     separation_strength (capped < 1.0 so a determined player can still
#     pin an enemy). This actively maintains spacing so two CharacterBody2Ds
#     never settle into a sticky locked-contact state.

@export var stop_distance: float = 60.0
@export var slow_band: float = 24.0
@export var separation_strength: float = 0.6


func compute_velocity(enemy: Enemy, _delta: float) -> Vector2:
	if enemy.target == null or not is_instance_valid(enemy.target):
		return Vector2.ZERO
	var to_target := enemy.target.global_position - enemy.global_position
	var dist := to_target.length()
	if dist < 0.001:
		return Vector2.ZERO

	# Outside the slowdown band: pathfind around obstacles via the nav agent.
	if dist >= stop_distance + slow_band:
		var nav_dir := enemy.nav_direction_to(enemy.target.global_position)
		if nav_dir == Vector2.ZERO:
			return Vector2.ZERO
		return nav_dir * enemy.movement_speed

	# Slowdown band: still nav-aware, but ramp speed down toward stop_distance.
	if dist >= stop_distance:
		var nav_dir := enemy.nav_direction_to(enemy.target.global_position)
		if nav_dir == Vector2.ZERO:
			return Vector2.ZERO
		var t := (dist - stop_distance) / slow_band
		return nav_dir * enemy.movement_speed * t

	# Inside stop_distance — line-of-sight contact, back off along the direct
	# vector proportional to overlap depth. Nav would be noisy here.
	var direction := to_target / dist
	var overlap_ratio: float = (stop_distance - dist) / stop_distance
	return -direction * enemy.movement_speed * separation_strength * overlap_ratio
