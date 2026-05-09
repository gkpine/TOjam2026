extends Node2D

@export var WORLD_SIZE := 1000.0
const TILE_SIZE := 64.0
const COLOR_A := Color(0.15, 0.15, 0.2)
const COLOR_B := Color(0.2, 0.2, 0.25)

var world_id: int = 0
var player: Player = null


func setup(world_index: int, player_scene: PackedScene, player_color: Color) -> void:
	world_id = world_index
	player = player_scene.instantiate()
	player.position = $SpawnPoint.position
	player.setup(world_index, player_color)
	add_child(player)
	GameState.register_player(world_index, player)
	var fcn := preload("res://scenes/combat/floating_combat_numbers.tscn").instantiate()
	add_child(fcn)
	var hud := preload("res://scenes/hud/hud.tscn").instantiate()
	add_child(hud)
	hud.setup(player)


func on_player_died() -> void:
	player = null


func _draw() -> void:
	var cols := int(WORLD_SIZE / TILE_SIZE)
	var rows := int(WORLD_SIZE / TILE_SIZE)
	var offset := -WORLD_SIZE / 2.0
	for row in range(-rows, rows):
		for col in range(-cols, cols):
			if col == -cols and row == -rows:
				# Top left corner
				$Map/TileMapLayer.set_cell(Vector2(row, col), 1, Vector2(5, 0))
			elif col == cols - 2 and row == rows - 1:
				# Bottom right corner grass
				$Map/TileMapLayer.set_cell(Vector2(row, col), 1, Vector2(7, 2))
			elif col == cols - 2 and row == -rows:
				# Bottom left corner grass
				$Map/TileMapLayer.set_cell(Vector2(row, col), 1, Vector2(5, 2))
			elif col == cols - 1 and row == -rows:
				# Bottom left corner rocks
				$Map/TileMapLayer.set_cell(Vector2(row, col), 1, Vector2(5, 4))
			elif col == cols - 1 and row == rows - 1:
				# Bottom right corner rocks
				$Map/TileMapLayer.set_cell(Vector2(row, col), 1, Vector2(7, 4))
			elif row == -rows:
				# Left edge
				$Map/TileMapLayer.set_cell(Vector2(row, col), 1, Vector2(5, 1))
			elif row == rows - 1 and col == -cols:
				# Top right corner
				$Map/TileMapLayer.set_cell(Vector2(row, col), 1, Vector2(7, 0))
			elif row == rows - 1:
				# Right edge
				$Map/TileMapLayer.set_cell(Vector2(row, col), 1, Vector2(7, 1))
			elif col == cols - 2:
				# Bottom edge
				$Map/TileMapLayer.set_cell(Vector2(row, col), 1, Vector2(6, 2))
			elif col == cols - 1:
				# Bottom rocks
				$Map/TileMapLayer.set_cell(Vector2(row, col), 1, Vector2(6, 4))
			elif col == -cols:
				# Top edge
				$Map/TileMapLayer.set_cell(Vector2(row, col), 1, Vector2(6, 0))
			else:
				# Middle grass tiles
				$Map/TileMapLayer.set_cell(Vector2(row, col), 1, Vector2(6, 1))
