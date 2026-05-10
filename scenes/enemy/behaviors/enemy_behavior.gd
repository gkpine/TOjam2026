class_name EnemyBehavior
extends Resource

# Strategy resource: each subclass implements compute_velocity() to drive a
# different movement style (chaser, charger, kiter, etc.). One instance is
# shared across every enemy that points at the same .tres, so behaviors must
# be stateless — per-enemy state lives on enemy.behavior_state (Dictionary).


# Non-movement actions: spawning minions, firing projectiles, FSM bookkeeping.
# Called once per physics frame before compute_velocity (and skipped while the
# enemy is casting). Default is a no-op so movement-only behaviors don't need
# to override it.
func tick(_enemy: Enemy, _delta: float) -> void:
	pass
	


func compute_velocity(_enemy: Enemy, _delta: float) -> Vector2:
	return Vector2.ZERO


# Called once per slide collision after move_and_slide. Override to react
# (e.g. ending a dash on impact). Default is a no-op.
func on_collision(_enemy: Enemy, _collision: KinematicCollision2D) -> void:
	pass
