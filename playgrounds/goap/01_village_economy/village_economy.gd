## Village Economy playground scene controller.
##
## Demonstrates multi-agent resource sharing, dynamic goal prioritization,[br]
## and emergent cooperation patterns through GOAP.
extends PlaygroundBase

## Number of villagers in the simulation.
@export var villager_count: int = 8

## Resource spawn rate multiplier (higher = more abundant).
@export var resource_spawn_rate: float = 1.0

## Need decay rate multiplier (higher = faster hunger/thirst).
@export var need_decay_rate: float = 1.0

## Villager actors (Node2D parent nodes).
var _villagers: Array[Node2D] = []

## Resource nodes in the world.
var _resource_nodes: Dictionary = {
	"food": [],
	"water": [],
	"wood": []
}

## Location zones.
var _locations: Dictionary = {}

## Shared stockpile (in shared blackboard).
var _shared_blackboard: GOAPState = GOAPState.new()


func _ready() -> void:
	super._ready()

	_setup_locations()
	_setup_resources()
	_spawn_villagers()
	_setup_shared_state()


func _process(delta: float) -> void:
	if is_paused:
		return

	# Update villager needs
	var adjusted_delta := delta * need_decay_rate
	for villager_actor in _villagers:
		var agent := villager_actor.get_node_or_null("VillagerAgent") as VillagerAgent
		if agent:
			agent.update_needs(adjusted_delta)

	# Update visuals
	queue_redraw()

	# Update debug metrics
	if debug_overlay and debug_overlay.visible:
		update_debug_metrics(_calculate_metrics())


func _draw() -> void:
	# Draw locations
	_draw_locations()

	# Draw resources
	_draw_resources()

	# Villagers draw themselves


## Sets up location zones.
func _setup_locations() -> void:
	_locations = {
		&"village": Rect2(Vector2(100, 100), Vector2(200, 200)),
		&"field": Rect2(Vector2(400, 100), Vector2(150, 150)),
		&"well": Rect2(Vector2(100, 400), Vector2(100, 100)),
		&"forest": Rect2(Vector2(400, 400), Vector2(150, 150)),
		&"stockpile": Rect2(Vector2(650, 250), Vector2(100, 100))
	}


## Sets up initial resources.
func _setup_resources() -> void:
	# Food nodes in field
	for i in range(5):
		var pos := _get_random_position_in_location(&"field")
		_resource_nodes["food"].append(pos)

	# Water nodes at well
	for i in range(3):
		var pos := _get_random_position_in_location(&"well")
		_resource_nodes["water"].append(pos)

	# Wood nodes in forest
	for i in range(6):
		var pos := _get_random_position_in_location(&"forest")
		_resource_nodes["wood"].append(pos)


## Spawns villagers in the village.
func _spawn_villagers() -> void:
	for i in range(villager_count):
		# Stagger spawning to desynchronize agent thinking
		await get_tree().create_timer(randf_range(0.05, 0.15)).timeout
		_spawn_villager(i)


## Spawns a single villager.
func _spawn_villager(index: int) -> void:
	# Create actor node with physics
	var actor := CharacterBody2D.new()
	actor.name = "Villager%d" % index
	actor.position = _get_random_position_in_location(&"village")
	actor.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING  # Top-down movement
	add_child(actor)

	# Add collision shape
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 8.0  # Slightly smaller than visual radius (12)
	collision.shape = shape
	actor.add_child(collision)

	# Create agent
	var agent := VillagerAgent.new()
	agent.name = "VillagerAgent"
	actor.add_child(agent)

	# Connect visual drawing
	if agent._visual:
		agent._visual.draw.connect(agent._on_visual_draw)

	_villagers.append(actor)
	register_agent(agent)


## Sets up shared blackboard state.
func _setup_shared_state() -> void:
	_shared_blackboard.set_value(&"stockpile_food", 0)
	_shared_blackboard.set_value(&"stockpile_water", 0)
	_shared_blackboard.set_value(&"stockpile_wood", 0)


## Resets the scenario.
func _reset_scenario() -> void:
	super._reset_scenario()

	# Remove all villagers
	for villager in _villagers:
		villager.queue_free()
	_villagers.clear()
	agents.clear()

	# Reset resources
	_resource_nodes = {"food": [], "water": [], "wood": []}
	_setup_resources()

	# Respawn villagers
	_spawn_villagers()

	# Reset shared state
	_setup_shared_state()


## Draws location zones.
func _draw_locations() -> void:
	for location_name in _locations:
		var rect: Rect2 = _locations[location_name]
		var color := VisualHelpers.Colors.LOCATION_NEUTRAL

		# Highlight stockpile
		if location_name == &"stockpile":
			color = Color(0.8, 0.6, 0.2, 0.4)

		VisualHelpers.draw_location_zone(self, rect, color, true)

		# Draw location label
		var center := rect.position + rect.size * 0.5
		VisualHelpers.draw_label(self, str(location_name), center, VisualHelpers.Colors.DEBUG_TEXT, 14)


## Draws resource nodes.
func _draw_resources() -> void:
	for resource_type in _resource_nodes:
		var nodes: Array = _resource_nodes[resource_type]
		for pos in nodes:
			VisualHelpers.draw_resource(self, resource_type, pos, 10.0)


## Calculates metrics for debug display.
func _calculate_metrics() -> Dictionary:
	var metrics := {}
	metrics["Villagers"] = _villagers.size()
	metrics["Food Nodes"] = _resource_nodes["food"].size()
	metrics["Water Nodes"] = _resource_nodes["water"].size()
	metrics["Wood Nodes"] = _resource_nodes["wood"].size()

	# Stockpile
	metrics["Stockpile Food"] = _shared_blackboard.get_value(&"stockpile_food", 0)
	metrics["Stockpile Water"] = _shared_blackboard.get_value(&"stockpile_water", 0)
	metrics["Stockpile Wood"] = _shared_blackboard.get_value(&"stockpile_wood", 0)

	# Agent states
	var idle_count := 0
	var planning_count := 0
	var performing_count := 0

	for agent in agents:
		match agent.get_state():
			GOAPAgent.State.IDLE:
				idle_count += 1
			GOAPAgent.State.PLANNING:
				planning_count += 1
			GOAPAgent.State.PERFORMING:
				performing_count += 1

	metrics["Idle"] = idle_count
	metrics["Planning"] = planning_count
	metrics["Performing"] = performing_count

	return metrics


## Gets a random position within a location zone.
func _get_random_position_in_location(location_name: StringName) -> Vector2:
	if not _locations.has(location_name):
		return Vector2.ZERO

	var rect: Rect2 = _locations[location_name]
	var x := randf_range(rect.position.x + 20, rect.position.x + rect.size.x - 20)
	var y := randf_range(rect.position.y + 20, rect.position.y + rect.size.y - 20)
	return Vector2(x, y)


## Gets the center position of a location.
func get_location_center(location_name: StringName) -> Vector2:
	if not _locations.has(location_name):
		return Vector2.ZERO

	var rect: Rect2 = _locations[location_name]
	return rect.position + rect.size * 0.5


## Gets a random position within a location (with margin from edges).
func get_random_location_position(location_name: StringName) -> Vector2:
	return _get_random_position_in_location(location_name)
