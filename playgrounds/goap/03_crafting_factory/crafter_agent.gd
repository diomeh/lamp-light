## Crafter agent for the Crafting Factory playground.
##
## Manages inventory, crafting operations, and station interactions.[br]
## Demonstrates deep action chain planning (5-7 steps).
class_name CrafterAgent
extends GOAPAgent

## Visual representation.
var _visual: Node2D

## Inventory - materials carried.
var inventory: Dictionary = {
	&"ore": 0,
	&"iron_ingot": 0,
	&"wood": 0,
	&"tool": 0,
	&"gear": 0,
	&"machine": 0
}

## Maximum inventory capacity.
const MAX_INVENTORY: int = 10

## Current station reservation (if any).
var reserved_station: Node = null

## Movement.
var move_speed: float = 120.0


func _init() -> void:
	super._init()


func _ready() -> void:
	super._ready()  # Must be first to set actor
	_setup_goals()
	_setup_actions()
	_initialize_blackboard()
	_create_visual()


## Sets up crafter goals.
func _setup_goals() -> void:
	goals = [
		FulfillOrderGoal.new(&"machine", 5),    # Tier 5 - Highest complexity
		FulfillOrderGoal.new(&"gear", 4),       # Tier 4
		FulfillOrderGoal.new(&"tool", 3),       # Tier 3
		FulfillOrderGoal.new(&"iron_ingot", 2), # Tier 2
		IdleGoal.new()                          # Fallback
	]


## Sets up crafter actions.
func _setup_actions() -> void:
	actions = [
		# Gathering raw materials
		MineOreAction.new(),
		GatherWoodAction.new(),

		# Crafting actions (5 tiers)
		SmeltIngotAction.new(),      # Tier 2: Ore → Ingot
		CraftToolAction.new(),       # Tier 3: Ingots + Wood → Tool
		CraftGearAction.new(),       # Tier 4: Ingots + Tool → Gear
		AssembleMachineAction.new(), # Tier 5: Gears + Tools → Machine

		# Logistics
		MoveToStationAction.new(),
		DepositProductAction.new(),
		RetrieveMaterialAction.new(),
		IdleAction.new()
	]


## Initializes crafter blackboard state.
func _initialize_blackboard() -> void:
	for material in inventory:
		blackboard.set_value(material, inventory[material])

	blackboard.set_value(&"inventory_space", MAX_INVENTORY)
	blackboard.set_value(&"at_station", &"none")
	blackboard.set_value(&"station_available", false)


## Creates visual representation.
func _create_visual() -> void:
	_visual = Node2D.new()
	_visual.name = "Visual"
	actor.add_child(_visual)
	_visual.draw.connect(_on_visual_draw)


## Draws the crafter.
func _on_visual_draw() -> void:
	if not _visual:
		return

	# Draw crafter circle
	var color := VisualHelpers.get_agent_state_color(self, false)
	VisualHelpers.draw_agent(_visual, color, 10.0)

	# Draw inventory indicator
	var total_items := 0
	for material in inventory:
		total_items += inventory[material]

	if total_items > 0:
		var fill := float(total_items) / float(MAX_INVENTORY)
		VisualHelpers.draw_progress_bar(_visual, Vector2(0, -18), Vector2(20, 4), fill, Color(0.8, 0.6, 0.2))

	# Draw current action label
	var current_action := get_current_action()
	if current_action:
		VisualHelpers.draw_label(_visual, str(current_action.action_name), Vector2(0, 20))


## Adds material to inventory.
func add_material(material: StringName, amount: int) -> bool:
	var total := 0
	for mat in inventory:
		total += inventory[mat]

	if total + amount > MAX_INVENTORY:
		return false

	inventory[material] = inventory.get(material, 0) + amount
	blackboard.set_value(material, inventory[material])
	_update_inventory_space()
	return true


## Removes material from inventory.
func remove_material(material: StringName, amount: int) -> bool:
	if inventory.get(material, 0) < amount:
		return false

	inventory[material] -= amount
	blackboard.set_value(material, inventory[material])
	_update_inventory_space()
	return true


## Checks if has required materials.
func has_materials(requirements: Dictionary) -> bool:
	for material in requirements:
		if inventory.get(material, 0) < requirements[material]:
			return false
	return true


## Updates inventory space in blackboard.
func _update_inventory_space() -> void:
	var total := 0
	for mat in inventory:
		total += inventory[mat]
	blackboard.set_value(&"inventory_space", MAX_INVENTORY - total)


## Moves toward a target position.
func move_toward(target_pos: Vector2, delta: float) -> float:
	if not actor is Node2D:
		return 0.0

	var current_pos: Vector2 = actor.global_position
	var direction := (target_pos - current_pos).normalized()
	var distance := current_pos.distance_to(target_pos)
	var move_amount := move_speed * delta

	if distance > move_amount:
		actor.global_position += direction * move_amount
		return distance
	else:
		actor.global_position = target_pos
		return 0.0


## Reserves a crafting station.
func reserve_station(station: Node) -> bool:
	if reserved_station:
		return false
	reserved_station = station
	return true


## Releases reserved station.
func release_station() -> void:
	reserved_station = null
