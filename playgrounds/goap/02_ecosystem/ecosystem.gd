## Ecosystem Simulation playground scene controller.
##
## Demonstrates predator-prey dynamics, environmental interaction,[br]
## and emergent population balance through GOAP.
extends PlaygroundBase

## Population configuration.
@export_group("Population")
@export var herbivore_count: int = 15
@export var predator_count: int = 3
@export var scavenger_count: int = 5

## Simulation parameters.
@export_group("Simulation")
@export var energy_decay_rate: float = 1.0
@export var grass_regrowth_rate: float = 1.0

## World bounds.
var _world_size: Vector2 = Vector2(800, 600)

## Grass patches (position -> health 0-100).
var _grass_patches: Dictionary = {}
const GRASS_PATCH_COUNT: int = 30

## Corpses (position -> remaining_food 0-100).
var _corpses: Dictionary = {}

## All creatures in the ecosystem.
var _creatures: Array[Node2D] = []

## Population tracking.
var _population_history: Dictionary = {
	"herbivore": [],
	"predator": [],
	"scavenger": []
}
var _history_interval: float = 1.0  # Record every second
var _history_timer: float = 0.0
const MAX_HISTORY_POINTS: int = 300  # 5 minutes at 1Hz

## Graph display toggle.
var _show_graph: bool = false


func _ready() -> void:
	super._ready()

	_spawn_grass_patches()
	_spawn_creatures()


func _process(delta: float) -> void:
	if is_paused:
		return

	# Update population tracking
	_update_population_history(delta)

	# Regenerate grass
	_regenerate_grass(delta * grass_regrowth_rate)

	# Cleanup empty corpses
	_cleanup_corpses()

	# Update visuals
	queue_redraw()

	# Update debug metrics
	if debug_overlay and debug_overlay.visible:
		update_debug_metrics(_calculate_metrics())


func _unhandled_input(event: InputEvent) -> void:
	super._unhandled_input(event)

	# G - Toggle population graph
	if event is InputEventKey and event.pressed and event.keycode == KEY_G:
		_show_graph = !_show_graph
		get_viewport().set_input_as_handled()


func _draw() -> void:
	# Draw grass patches
	_draw_grass_patches()

	# Draw corpses
	_draw_corpses()

	# Draw population graph if enabled
	if _show_graph:
		_draw_population_graph()

	# Creatures draw themselves


## Spawns initial grass patches.
func _spawn_grass_patches() -> void:
	for i in range(GRASS_PATCH_COUNT):
		var pos := Vector2(
			randf_range(50, _world_size.x - 50),
			randf_range(50, _world_size.y - 50)
		)
		_grass_patches[pos] = 100.0  # Full health


## Spawns initial creature populations.
func _spawn_creatures() -> void:
	# Spawn herbivores
	for i in range(herbivore_count):
		_spawn_creature(CreatureAgent.CreatureType.HERBIVORE)

	# Spawn predators
	for i in range(predator_count):
		_spawn_creature(CreatureAgent.CreatureType.PREDATOR)

	# Spawn scavengers
	for i in range(scavenger_count):
		_spawn_creature(CreatureAgent.CreatureType.SCAVENGER)


## Spawns a single creature of the specified type.
func _spawn_creature(type: CreatureAgent.CreatureType) -> void:
	var actor := Node2D.new()
	actor.position = get_random_position()
	add_child(actor)

	var creature: CreatureAgent
	match type:
		CreatureAgent.CreatureType.HERBIVORE:
			actor.name = "Herbivore%d" % _creatures.size()
			creature = Herbivore.new()
		CreatureAgent.CreatureType.PREDATOR:
			actor.name = "Predator%d" % _creatures.size()
			creature = Predator.new()
		CreatureAgent.CreatureType.SCAVENGER:
			actor.name = "Scavenger%d" % _creatures.size()
			creature = Scavenger.new()

	if creature:
		creature.name = "CreatureAgent"
		actor.add_child(creature)
		_creatures.append(actor)
		register_agent(creature)


## Spawns offspring near parent.
func spawn_offspring(parent: CreatureAgent) -> void:
	if not parent or not is_instance_valid(parent):
		return

	var offset := Vector2(randf_range(-30, 30), randf_range(-30, 30))
	var spawn_pos: Vector2 = parent.actor.global_position + offset

	var actor := Node2D.new()
	actor.position = spawn_pos
	add_child(actor)

	var offspring: CreatureAgent
	match parent.creature_type:
		CreatureAgent.CreatureType.HERBIVORE:
			actor.name = "Herbivore%d" % _creatures.size()
			offspring = Herbivore.new()
		CreatureAgent.CreatureType.PREDATOR:
			actor.name = "Predator%d" % _creatures.size()
			offspring = Predator.new()
		CreatureAgent.CreatureType.SCAVENGER:
			actor.name = "Scavenger%d" % _creatures.size()
			offspring = Scavenger.new()

	if offspring:
		offspring.name = "CreatureAgent"
		offspring.energy = 50.0  # Start with moderate energy
		actor.add_child(offspring)
		_creatures.append(actor)
		register_agent(offspring)


## Called when a creature dies.
func _on_creature_died(creature: CreatureAgent) -> void:
	if not creature or not is_instance_valid(creature):
		return

	# Create corpse at death location
	var corpse_pos: Vector2 = creature.actor.global_position
	_corpses[corpse_pos] = 100.0  # Full corpse

	# Remove creature after a delay (visual feedback)
	await get_tree().create_timer(2.0).timeout

	if is_instance_valid(creature) and is_instance_valid(creature.actor):
		_creatures.erase(creature.actor)
		unregister_agent(creature)
		creature.actor.queue_free()


## Finds nearest grass patch to a position.
func find_nearest_grass(from_pos: Vector2) -> Vector2:
	var nearest_pos := Vector2.ZERO
	var nearest_dist := INF

	for grass_pos in _grass_patches.keys():
		var health: float = _grass_patches[grass_pos]
		if health < 20.0:  # Skip depleted grass
			continue

		var dist := from_pos.distance_to(grass_pos)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest_pos = grass_pos

	return nearest_pos if nearest_dist < INF else from_pos


## Consumes grass at a location.
func consume_grass(pos: Vector2, amount: float) -> void:
	# Find closest grass patch
	var closest_patch: Vector2 = Vector2.ZERO
	var closest_dist := INF

	for grass_pos in _grass_patches.keys():
		var dist := pos.distance_to(grass_pos)
		if dist < closest_dist:
			closest_dist = dist
			closest_patch = grass_pos

	if closest_dist < 20.0 and _grass_patches.has(closest_patch):
		_grass_patches[closest_patch] = maxf(_grass_patches[closest_patch] - amount, 0.0)


## Regenerates grass over time.
func _regenerate_grass(delta_rate: float) -> void:
	for grass_pos in _grass_patches.keys():
		var health: float = _grass_patches[grass_pos]
		if health < 100.0:
			_grass_patches[grass_pos] = minf(health + delta_rate * 5.0, 100.0)


## Gets all corpse positions.
func get_corpses() -> Array:
	return _corpses.keys()


## Consumes corpse at a location.
func consume_corpse(pos: Vector2, amount: float) -> void:
	# Find closest corpse
	var closest_corpse: Vector2 = Vector2.ZERO
	var closest_dist := INF

	for corpse_pos in _corpses.keys():
		var dist := pos.distance_to(corpse_pos)
		if dist < closest_dist:
			closest_dist = dist
			closest_corpse = corpse_pos

	if closest_dist < 20.0 and _corpses.has(closest_corpse):
		_corpses[closest_corpse] = maxf(_corpses[closest_corpse] - amount, 0.0)


## Cleans up fully consumed corpses.
func _cleanup_corpses() -> void:
	var to_remove: Array[Vector2] = []
	for corpse_pos in _corpses.keys():
		if _corpses[corpse_pos] <= 0.0:
			to_remove.append(corpse_pos)

	for pos in to_remove:
		_corpses.erase(pos)


## Gets all living creatures.
func get_all_creatures() -> Array:
	var living: Array = []
	for creature_actor in _creatures:
		if is_instance_valid(creature_actor):
			var agent := creature_actor.get_node_or_null("CreatureAgent") as CreatureAgent
			if agent and not agent.is_dead:
				living.append(agent)
	return living


## Gets a random position in the world.
func get_random_position() -> Vector2:
	return Vector2(
		randf_range(50, _world_size.x - 50),
		randf_range(50, _world_size.y - 50)
	)


## Draws grass patches.
func _draw_grass_patches() -> void:
	for grass_pos in _grass_patches.keys():
		var health: float = _grass_patches[grass_pos]
		var color := Color(0.2, 0.6, 0.2, health / 100.0)
		draw_circle(grass_pos, 12.0, color)


## Draws corpses.
func _draw_corpses() -> void:
	for corpse_pos in _corpses.keys():
		var remaining: float = _corpses[corpse_pos]
		var size := 8.0 * (remaining / 100.0)
		draw_circle(corpse_pos, size, Color(0.4, 0.2, 0.1))


## Updates population history for graphing.
func _update_population_history(delta: float) -> void:
	_history_timer += delta

	if _history_timer >= _history_interval:
		_history_timer = 0.0

		var counts := _count_populations()

		for type_name in ["herbivore", "predator", "scavenger"]:
			_population_history[type_name].append(counts[type_name])

			# Limit history length
			if _population_history[type_name].size() > MAX_HISTORY_POINTS:
				_population_history[type_name].pop_front()


## Counts current populations by type.
func _count_populations() -> Dictionary:
	var counts := {"herbivore": 0, "predator": 0, "scavenger": 0}

	for creature_actor in _creatures:
		if not is_instance_valid(creature_actor):
			continue

		var agent := creature_actor.get_node_or_null("CreatureAgent") as CreatureAgent
		if not agent or agent.is_dead:
			continue

		match agent.creature_type:
			CreatureAgent.CreatureType.HERBIVORE:
				counts["herbivore"] += 1
			CreatureAgent.CreatureType.PREDATOR:
				counts["predator"] += 1
			CreatureAgent.CreatureType.SCAVENGER:
				counts["scavenger"] += 1

	return counts


## Draws population graph overlay.
func _draw_population_graph() -> void:
	var graph_rect := Rect2(Vector2(600, 50), Vector2(180, 120))
	draw_rect(graph_rect, Color(0.1, 0.1, 0.1, 0.8))

	# Title
	var font := ThemeDB.fallback_font
	draw_string(font, graph_rect.position + Vector2(10, 15), "Population", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)

	# Draw lines for each population
	var colors := {
		"herbivore": Color(0.3, 0.8, 0.3),
		"predator": Color(0.8, 0.2, 0.2),
		"scavenger": Color(0.7, 0.5, 0.2)
	}

	var max_pop := 25.0  # Y-axis scale

	for type_name in ["herbivore", "predator", "scavenger"]:
		var history: Array = _population_history[type_name]
		if history.size() < 2:
			continue

		var points: PackedVector2Array = []
		for i in range(history.size()):
			var x := graph_rect.position.x + 10 + (i / float(MAX_HISTORY_POINTS)) * (graph_rect.size.x - 20)
			var pop: int = history[i]
			var y := graph_rect.position.y + graph_rect.size.y - 10 - (pop / max_pop) * (graph_rect.size.y - 30)
			points.append(Vector2(x, y))

		if points.size() > 1:
			VisualHelpers.draw_path(self, points, colors[type_name], 2.0)


## Calculates metrics for debug display.
func _calculate_metrics() -> Dictionary:
	var counts := _count_populations()
	var metrics := {}

	metrics["Herbivores"] = counts["herbivore"]
	metrics["Predators"] = counts["predator"]
	metrics["Scavengers"] = counts["scavenger"]
	metrics["Total"] = counts["herbivore"] + counts["predator"] + counts["scavenger"]
	metrics["Grass Patches"] = _grass_patches.size()
	metrics["Corpses"] = _corpses.size()

	return metrics


## Resets the scenario.
func _reset_scenario() -> void:
	super._reset_scenario()

	# Remove all creatures
	for creature_actor in _creatures:
		if is_instance_valid(creature_actor):
			creature_actor.queue_free()
	_creatures.clear()
	agents.clear()

	# Reset environment
	_grass_patches.clear()
	_corpses.clear()
	_population_history = {"herbivore": [], "predator": [], "scavenger": []}

	# Respawn
	_spawn_grass_patches()
	_spawn_creatures()
