class_name DebugSpawnCounter
extends CanvasLayer

# Dev tool: on-screen counter listing every SpawnRegion under the parent
# world and its alive/cap, plus a total. Mounted only inside player 0's
# world (see scenes/world/world.gd:setup). Press F3 to toggle visibility.

const TOGGLE_KEY := KEY_F3
const REFRESH_INTERVAL := 0.25
const PANEL_OFFSET := Vector2(16, 16)
const PANEL_WIDTH := 280.0

var _world: Node2D
var _label: Label
var _accum := 0.0


func _ready() -> void:
	layer = 11
	_world = get_parent() as Node2D
	_label = Label.new()
	_label.position = PANEL_OFFSET
	_label.size = Vector2(PANEL_WIDTH, 0)
	_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_label.add_theme_constant_override("outline_size", 4)
	_label.visible = false
	add_child(_label)
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.physical_keycode == TOGGLE_KEY:
		_label.visible = not _label.visible
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	# Hidden? Skip the per-region polling entirely — no point counting if
	# nobody's reading.
	if not _label.visible:
		return
	_accum += delta
	if _accum < REFRESH_INTERVAL:
		return
	_accum = 0.0
	_refresh()


func _refresh() -> void:
	if _world == null or not is_instance_valid(_world):
		return
	# Sort by node name so the list is stable across frames — find_children
	# returns them in tree order, which is fine, but a deterministic name
	# sort is easier to scan when several regions hover near their cap.
	var regions := _world.find_children("*", "SpawnRegion", true, false)
	regions.sort_custom(func(a, b): return String(a.name) < String(b.name))
	var lines := PackedStringArray()
	var total := 0
	var cap_total := 0
	for r in regions:
		var sr := r as SpawnRegion
		var alive := sr.alive_count()
		total += alive
		cap_total += sr.max_alive
		lines.append("  %s: %d/%d" % [sr.name, alive, sr.max_alive])
	_label.text = "Enemies %d/%d  (F3 to toggle)\n%s" % [total, cap_total, "\n".join(lines)]
