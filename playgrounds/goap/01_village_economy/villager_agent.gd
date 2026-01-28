## Villager agent for the Village Economy playground.
##
## Manages survival needs (hunger, thirst, stamina) while contributing to[br]
## community resources. Demonstrates multi-agent coordination via shared blackboard.
class_name VillagerAgent
extends GOAPAgent

## Visual representation of the villager.
var _visual: Node2D

## Current needs
var hunger: float = randf_range(0.0, 30.0)  # 0-100, start with some variation
var thirst: float = randf_range(0.0, 30.0)  # 0-100, start with some variation
var stamina: float = randf_range(70.0, 100.0)  # 0-100, start with some variation

## Inventory
var has_food: bool = false
var has_water: bool = false
var has_wood: bool = false

## Current location
var current_location: StringName = &"village"

## Movement
var move_speed: float = 100.0


func _init() -> void:
	super._init()


func _ready() -> void:
	super._ready()  # Must be first to set actor

	# Set up goals and actions (will be loaded as resources)
	_setup_goals()
	_setup_actions()
	_initialize_blackboard()

	# Create visual representation
	_create_visual()


## Sets up villager goals.
func _setup_goals() -> void:
	goals = [
		SurviveHungerGoal.new(),
		SurviveThirstGoal.new(),
		RestGoal.new(),
		ContributeGoal.new()
	]


## Sets up villager actions.
func _setup_actions() -> void:
	# Create movement actions for each location
	var move_to_field := MoveToAction.new(&"field")
	var move_to_well := MoveToAction.new(&"well")
	var move_to_forest := MoveToAction.new(&"forest")
	var move_to_village := MoveToAction.new(&"village")
	var move_to_stockpile := MoveToAction.new(&"stockpile")

	# Create gathering actions
	var gather_food := GatherFoodAction.new()
	var fetch_water := FetchWaterAction.new()
	var gather_wood := GatherWoodAction.new()

	# Create consumption actions
	var eat_food := EatFoodAction.new()
	var drink_water := DrinkWaterAction.new()
	var rest := RestAction.new()

	# Create contribution action
	var deposit := DepositResourcesAction.new()

	actions = [
		move_to_field, move_to_well, move_to_forest, move_to_village, move_to_stockpile,
		gather_food, fetch_water, gather_wood,
		eat_food, drink_water, rest,
		deposit
	]


## Initializes villager blackboard state.
func _initialize_blackboard() -> void:
	blackboard.set_value(&"hunger", hunger)
	blackboard.set_value(&"thirst", thirst)
	blackboard.set_value(&"stamina", stamina)
	blackboard.set_value(&"has_food", has_food)
	blackboard.set_value(&"has_water", has_water)
	blackboard.set_value(&"has_wood", has_wood)
	blackboard.set_value(&"at_location", current_location)


## Creates visual representation.
func _create_visual() -> void:
	_visual = Node2D.new()
	_visual.name = "Visual"
	actor.add_child(_visual)


## Updates needs over time.
func update_needs(delta: float) -> void:
	# Decay needs
	hunger = minf(hunger + delta * 5.0 * .5, 100.0)  # Hunger increases by 5/sec
	thirst = minf(thirst + delta * 7.0 * .25, 100.0)  # Thirst increases by 7/sec

	# Stamina regenerates slowly if not working
	if not is_performing():
		stamina = minf(stamina + delta * 2.0, 100.0)

	# Update blackboard
	blackboard.set_value(&"hunger", hunger)
	blackboard.set_value(&"thirst", thirst)
	blackboard.set_value(&"stamina", stamina)


## Draws the villager.
func draw_villager(_is_selected: bool = false) -> void:
	if not _visual:
		return

	_visual.queue_redraw()


func _on_visual_draw() -> void:
	if not _visual:
		return

	# Draw villager circle
	var color := VisualHelpers.get_agent_state_color(self, false)
	VisualHelpers.draw_agent(_visual, color, 12.0)

	# Draw needs indicators
	if hunger > 30.0:
		VisualHelpers.draw_need_indicator(_visual, Vector2(0, -20), hunger, "H", 70.0)
	if thirst > 30.0:
		VisualHelpers.draw_need_indicator(_visual, Vector2(0, -28), thirst, "T", 70.0)

	# Draw inventory indicators
	var inv_pos := Vector2(15, -10)
	if has_food:
		_visual.draw_circle(inv_pos, 3, VisualHelpers.Colors.RESOURCE_FOOD)
		inv_pos.y += 6
	if has_water:
		_visual.draw_circle(inv_pos, 3, VisualHelpers.Colors.RESOURCE_WATER)
		inv_pos.y += 6
	if has_wood:
		_visual.draw_circle(inv_pos, 3, VisualHelpers.Colors.RESOURCE_WOOD)

	# Draw current action label
	var current_action := get_current_action()
	if current_action:
		VisualHelpers.draw_label(_visual, str(current_action.action_name), Vector2(0, 25))


## Moves toward a target position using physics-based movement with collision.
## Returns the remaining distance to target.
func move_toward(target_pos: Vector2, _delta: float) -> float:
	if not actor is CharacterBody2D:
		return 0.0

	var body := actor as CharacterBody2D
	var current_pos: Vector2 = body.global_position
	var direction: Vector2 = (target_pos - current_pos).normalized()
	var distance: float = current_pos.distance_to(target_pos)

	# Set velocity and move with collision
	body.velocity = direction * move_speed
	body.move_and_slide()

	return distance
