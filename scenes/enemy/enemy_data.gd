class_name EnemyData
extends Resource

@export var enemy_name: String
@export var behavior: EnemyBehavior  # null → enemy.gd falls back to the chaser
@export var frame_size: int = 192
@export var visible_sprite_height: int = 173
@export var idle_frames: int = 8
@export var attack_frames: int = 7
@export var run_frames: int = 6

# Optional sprite overrides. When set, these are used instead of auto-loading
# from res://assets/enemies/{enemy_name}/{enemy_name}_{idle|attack|run}.png.
@export var idle_texture_override: Texture2D
@export var attack_texture_override: Texture2D
@export var run_texture_override: Texture2D

@export var health: float = 30.0
@export var max_health: float = 0.0
@export var base_damage: float = 5.0
@export var strength: float = 0.0
@export var auto_attack_enabled: bool = true
@export var auto_attack_per_second: float = 0.8
@export var auto_attack_delay: float = 0.3
@export var movement_speed: float = 120.0
@export var target_range_px: float = 250.0
@export var auto_attack_range_px: float = 80.0
@export var collision_radius: float = 16.0
@export var exp_reward: float = 10.0
@export var base_health_regen_per_second: float = 0.0
@export var in_combat_health_regen_multiplier: float = 0.0
@export var moving_hp_regen_multiplier: float = 0.25
@export var loot_table: Dictionary = {}

@export_group("Difficulty Scaling")
## Added to [member strength] per unit of difficulty. The enemy's runtime
## strength becomes `strength + difficulty_scale_strength * difficulty`,
## where `difficulty = global_difficulty * spawner.relative_difficulty`.
@export var difficulty_scale_strength: float = 0.0
## Added to [member max_health] per unit of difficulty. Same formula as
## [member difficulty_scale_strength]; current health is reset to the new
## max when scaling is applied during setup.
@export var difficulty_scale_max_health: float = 0.0
