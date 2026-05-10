extends Control

const WorldScene := preload("res://scenes/world/world.tscn")
const PlayerScene := preload("res://scenes/player/player.tscn")
const SEPARATOR_WIDTH := 2.0
const SEPARATOR_COLOR := Color(0.3, 0.3, 0.3)


func _ready() -> void:
	GameState.reset()
	var count := GameState.player_count
	var screen_size := get_viewport().get_visible_rect().size

	for i in range(count):
		var container := SubViewportContainer.new()
		container.stretch = true
		# Container + viewport must keep processing input during pause so the
		# winner overlay's mouse clicks reach their buttons. Pause is set on the
		# whole tree when a winner is declared, and a default-INHERIT container
		# would stop forwarding InputEventMouseButton at that point (mouse_entered
		# still fires via the engine's hover tracking, which is why hover used
		# to work but clicks didn't).
		container.process_mode = Node.PROCESS_MODE_ALWAYS
		_set_container_rect(container, i, count, screen_size)
		add_child(container)

		var viewport := SubViewport.new()
		viewport.handle_input_locally = false
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		viewport.audio_listener_enable_2d = true
		viewport.process_mode = Node.PROCESS_MODE_ALWAYS
		container.add_child(viewport)

		var world := WorldScene.instantiate()
		viewport.add_child(world)
		# World stays PAUSABLE so gameplay (enemies, spawners, player physics)
		# actually freezes when the tree is paused. The winner overlay sets its
		# own process_mode to ALWAYS inside its setup(), so it stays interactive.
		world.process_mode = Node.PROCESS_MODE_PAUSABLE
		world.setup(i, PlayerScene, GameState.PLAYER_COLORS[i])
		GameState.register_world(i, world)

	if count > 1:
		_add_separators(count, screen_size)

	GameState.winner_declared.connect(_on_winner_declared)


func _on_winner_declared(_winner_index: int) -> void:
	get_tree().paused = true


func _set_container_rect(container: SubViewportContainer, index: int, count: int, screen: Vector2) -> void:
	match count:
		1:
			container.position = Vector2.ZERO
			container.size = screen
		2:
			var w := screen.x / 2.0
			container.position = Vector2(index * w, 0)
			container.size = Vector2(w, screen.y)
		3:
			var w := screen.x / 3.0
			container.position = Vector2(index * w, 0)
			container.size = Vector2(w, screen.y)
		4:
			var col := index % 2
			var row := index / 2
			container.position = Vector2(col * screen.x / 2.0, row * screen.y / 2.0)
			container.size = Vector2(screen.x / 2.0, screen.y / 2.0)


func _add_separators(count: int, screen: Vector2) -> void:
	var hw := SEPARATOR_WIDTH / 2.0
	match count:
		2:
			_add_line(Vector2(screen.x / 2.0 - hw, 0), Vector2(SEPARATOR_WIDTH, screen.y))
		3:
			for i in [1, 2]:
				_add_line(Vector2(i * screen.x / 3.0 - hw, 0), Vector2(SEPARATOR_WIDTH, screen.y))
		4:
			_add_line(Vector2(screen.x / 2.0 - hw, 0), Vector2(SEPARATOR_WIDTH, screen.y))
			_add_line(Vector2(0, screen.y / 2.0 - hw), Vector2(screen.x, SEPARATOR_WIDTH))


func _add_line(pos: Vector2, rect_size: Vector2) -> void:
	var line := ColorRect.new()
	line.position = pos
	line.size = rect_size
	line.color = SEPARATOR_COLOR
	add_child(line)
