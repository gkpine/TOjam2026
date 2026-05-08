class_name EnemyData
extends Resource

@export var enemy_name: String
@export var frame_size: int = 192
@export var idle_frames: int = 8
@export var attack_frames: int = 7
@export var run_frames: int = 6

@export var health: float = 30.0
@export var base_damage: float = 5.0
@export var strength: float = 0.0
@export var auto_attack_per_second: float = 0.8
@export var movement_speed: float = 120.0
@export var target_range_px: float = 250.0
@export var auto_attack_range_px: float = 80.0
