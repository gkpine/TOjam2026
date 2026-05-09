class_name ChargerBehavior
extends EnemyBehavior

# Four-phase FSM:
#   APPROACH  — walk toward target at approach_speed_multiplier × movement_speed
#   WINDUP    — stand still for windup_time, then lock direction
#   CHARGING  — dash at charge_speed in locked direction until distance/time cap
#   RECOVER   — stand still for recover_time, then back to APPROACH
#
# Per-enemy state lives in enemy.behavior_state under these keys:
#   phase: int      — one of the PHASE_* constants
#   timer: float    — seconds spent in the current phase
#   dir:   Vector2  — locked direction during CHARGING
#   origin:Vector2  — global_position at charge start (for distance cap)

const PHASE_APPROACH := 0
const PHASE_WINDUP := 1
const PHASE_CHARGING := 2
const PHASE_RECOVER := 3

@export var trigger_range: float = 220.0
@export var windup_time: float = 0.5
@export var charge_speed: float = 420.0
@export var charge_distance: float = 280.0
@export var charge_max_time: float = 0.8
@export var recover_time: float = 1.0
@export var approach_speed_multiplier: float = 0.6
@export var stop_distance: float = 50.0


func compute_velocity(enemy: Enemy, delta: float) -> Vector2:
	var s := enemy.behavior_state
	if not s.has("phase"):
		s["phase"] = PHASE_APPROACH
		s["timer"] = 0.0
		s["dir"] = Vector2.ZERO
		s["origin"] = Vector2.ZERO

	if enemy.target == null or not is_instance_valid(enemy.target):
		s["phase"] = PHASE_APPROACH
		s["timer"] = 0.0
		return Vector2.ZERO

	s["timer"] = (s["timer"] as float) + delta
	var phase: int = s["phase"]

	match phase:
		PHASE_APPROACH:
			var dist := enemy.global_position.distance_to(enemy.target.global_position)
			if dist <= trigger_range:
				s["phase"] = PHASE_WINDUP
				s["timer"] = 0.0
				return Vector2.ZERO
			if dist <= stop_distance:
				return Vector2.ZERO
			var dir := (enemy.target.global_position - enemy.global_position).normalized()
			return dir * enemy.movement_speed * approach_speed_multiplier

		PHASE_WINDUP:
			if (s["timer"] as float) >= windup_time:
				s["phase"] = PHASE_CHARGING
				s["timer"] = 0.0
				s["origin"] = enemy.global_position
				s["dir"] = (enemy.target.global_position - enemy.global_position).normalized()
			return Vector2.ZERO

		PHASE_CHARGING:
			var traveled := enemy.global_position.distance_to(s["origin"])
			if (s["timer"] as float) >= charge_max_time or traveled >= charge_distance:
				s["phase"] = PHASE_RECOVER
				s["timer"] = 0.0
				return Vector2.ZERO
			return (s["dir"] as Vector2) * charge_speed

		PHASE_RECOVER:
			if (s["timer"] as float) >= recover_time:
				s["phase"] = PHASE_APPROACH
				s["timer"] = 0.0
			return Vector2.ZERO

	return Vector2.ZERO


func on_collision(enemy: Enemy, _collision: KinematicCollision2D) -> void:
	# End the dash on any contact while charging (player or wall). Other phases
	# don't care about collisions — the charger just walks/stands.
	var s := enemy.behavior_state
	if (s.get("phase", PHASE_APPROACH) as int) != PHASE_CHARGING:
		return
	s["phase"] = PHASE_RECOVER
	s["timer"] = 0.0
