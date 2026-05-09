extends CanvasLayer

var _player: Player = null

@onready var health_bar: Control = $HealthBar


func setup(player: Player) -> void:
	_player = player
	health_bar.update_health(player.health, player.max_health)
	player.damage_taken.connect(_on_player_damage_taken)
	player.died.connect(_on_player_died)


func _on_player_damage_taken(_amount: int, _world_pos: Vector2, _damage_type: String) -> void:
	if _player:
		health_bar.update_health(_player.health, _player.max_health)


func _on_player_died(_character: Character) -> void:
	if _player:
		health_bar.update_health(0.0, _player.max_health)
	_player = null
