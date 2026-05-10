class_name CasterBehavior
extends EnemyBehavior

# Walks toward target like a chaser, but periodically stops to channel an
# ability when the target is within cast_range and the cooldown is ready.
# The enemy stays still during the channel because enemy.gd respects
# is_casting (see Character.start_cast).
#
# Per-enemy state lives in enemy.behavior_state["cast_cd"].

@export var ability: AbilityData
@export var stop_distance: float = 80.0
@export var cast_range: float = 240.0
@export var cast_cooldown: float = 4.0    # seconds between casts after one finishes
@export var initial_cooldown: float = 2.0 # delay before the first cast


func compute_velocity(enemy: Enemy, delta: float) -> Vector2:
	if enemy.target == null or not is_instance_valid(enemy.target):
		return Vector2.ZERO

	var s := enemy.behavior_state
	if not s.has("cast_cd"):
		s["cast_cd"] = initial_cooldown
	s["cast_cd"] = maxf((s["cast_cd"] as float) - delta, 0.0)

	var to_target := enemy.target.global_position - enemy.global_position
	var dist := to_target.length()

	if ability != null and dist <= cast_range and (s["cast_cd"] as float) <= 0.0:
		enemy.start_cast(ability)
		s["cast_cd"] = cast_cooldown
		return Vector2.ZERO

	if dist <= stop_distance or dist < 0.001:
		return Vector2.ZERO
	var direction := enemy.nav_direction_to(enemy.target.global_position)
	if direction == Vector2.ZERO:
		return Vector2.ZERO
	return direction * enemy.movement_speed
