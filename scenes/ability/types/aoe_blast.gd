class_name AoeBlastData
extends AbilityData

# Generic circular AoE: telegraphs a ground circle during the cast, then on
# completion damages every Character within radius except the caster. Works
# for either side — enemies cast it at the player, the player can cast it
# at enemies, etc. Friendly fire is implicit (anyone in the circle gets hit
# except the caster); add filter exports later if you need to discriminate.

@export var radius: float = 150.0
@export var damage: float = 25.0
@export var indicator_fill: Color = Color(1.0, 0.2, 0.2, 0.25)
@export var indicator_border: Color = Color(1.0, 0.2, 0.2, 0.9)


func apply_effect(caster: Character, _target_player: Player = null) -> void:
	if caster == null or not is_instance_valid(caster):
		return
	var world := caster.get_parent()
	if world == null:
		return
	var origin := caster.global_position
	for child in world.get_children():
		if child == caster or not (child is Character) or not is_instance_valid(child):
			continue
		if origin.distance_to((child as Node2D).global_position) <= radius:
			(child as Character).take_damage(damage, "ability", caster)


func make_cast_indicator(_caster: Character) -> Node2D:
	var ind := AoeIndicator.new()
	ind.indicator_radius = radius
	ind.fill_color = indicator_fill
	ind.border_color = indicator_border
	ind.setup()
	return ind
