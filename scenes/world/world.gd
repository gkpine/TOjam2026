extends Node2D

const WORLD_SIZE := 2000.0
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


func _draw() -> void:
	var cols := int(WORLD_SIZE / TILE_SIZE)
	var rows := int(WORLD_SIZE / TILE_SIZE)
	var offset := -WORLD_SIZE / 2.0
	for row in range(rows):
		for col in range(cols):
			var color := COLOR_A if (row + col) % 2 == 0 else COLOR_B
			var rect := Rect2(
				offset + col * TILE_SIZE,
				offset + row * TILE_SIZE,
				TILE_SIZE,
				TILE_SIZE
			)
			draw_rect(rect, color)
