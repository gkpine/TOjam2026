class_name EnemyBehavior
extends Resource

# Strategy resource: each subclass implements compute_velocity() to drive a
# different movement style (chaser, charger, kiter, etc.). One instance is
# shared across every enemy that points at the same .tres, so behaviors must
# be stateless — per-enemy state lives on enemy.behavior_state (Dictionary).


func compute_velocity(_enemy: Enemy, _delta: float) -> Vector2:
	return Vector2.ZERO


# Called once per slide collision after move_and_slide. Override to react
# (e.g. ending a dash on impact). Default is a no-op.
func on_collision(_enemy: Enemy, _collision: KinematicCollision2D) -> void:
	pass
