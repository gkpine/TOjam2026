class_name SpawnEntry
extends Resource

## One row in a [SpawnRegion]'s `spawn_distribution`. Picking the next enemy
## to spawn is a weighted random over every entry's [member weight], so
## values of {2, 1, 1} behave the same as {0.5, 0.25, 0.25} — auto-normalized
## at sample time. Entries with `weight <= 0` are ignored.

@export var enemy_type: EnemyData
@export var weight: float = 1.0
