## Base creature agent for the Ecosystem playground.
##
## Shared functionality for all creature types (herbivores, predators, scavengers).[br]
## Manages energy, reproduction, death, and basic behaviors.
class_name CreatureAgent
extends GOAPAgent

## Creature type for identification.
enum CreatureType {
	HERBIVORE,
	PREDATOR,
	SCAVENGER
}

## This creature's type.
var creature_type: CreatureType = CreatureType.HERBIVORE

## Visual representation.
var _visual: Node2D

## Energy level (0-100). Death at 0, reproduction possible above threshold.
var energy: float = 50.0

## Age in seconds.
var age: float = 0.0

## Maximum lifespan in seconds.
var max_lifespan: float = 120.0

## Reproduction energy threshold.
var reproduction_threshold: float = 80.0

## Movement speed.
var move_speed: float = 80.0

## Creature size/radius for collision and visual.
var size: float = 8.0

## Whether creature is dead.
var is_dead: bool = false

## Target for hunting/fleeing (if applicable).
var target_creature: CreatureAgent = null

## Nearby detected threat (for fleeing).
var detected_threat: CreatureAgent = null


func _init() -> void:
	super._init()


func _ready() -> void:
	super._ready()  # Must be first to set actor
	_initialize_blackboard()
	_create_visual()


func _process(delta: float) -> void:
	if is_dead:
		return

	age += delta
	_update_energy(delta)
	_check_death()


## Initializes creature blackboard state.
func _initialize_blackboard() -> void:
	blackboard.set_value(&"energy", energy)
	blackboard.set_value(&"age", age)
	blackboard.set_value(&"can_reproduce", false)
	blackboard.set_value(&"is_dead", false)


## Updates energy over time.
func _update_energy(delta: float) -> void:
	# Base energy decay (hunger)
	energy = maxf(energy - delta * 2.0, 0.0)

	# Update blackboard
	blackboard.set_value(&"energy", energy)
	blackboard.set_value(&"can_reproduce", energy >= reproduction_threshold)


## Checks if creature should die.
func _check_death() -> void:
	if energy <= 0.0 or age >= max_lifespan:
		die()


## Kills this creature.
func die() -> void:
	if is_dead:
		return

	is_dead = true
	blackboard.set_value(&"is_dead", true)
	abort()  # Stop any current plan

	# Notify ecosystem
	var ecosystem := actor.get_parent() as Node
	if ecosystem and ecosystem.has_method("_on_creature_died"):
		ecosystem._on_creature_died(self)


## Eats food to restore energy.
func eat(amount: float) -> void:
	energy = minf(energy + amount, 100.0)
	blackboard.set_value(&"energy", energy)


## Creates visual representation.
func _create_visual() -> void:
	_visual = Node2D.new()
	_visual.name = "Visual"
	actor.add_child(_visual)


## Draws the creature (called by child classes).
func draw_creature(_color: Color, _is_selected: bool = false) -> void:
	if not _visual:
		return

	_visual.queue_redraw()


## Generic visual drawing function (override in subclasses for custom visuals).
func _on_visual_draw() -> void:
	if not _visual or is_dead:
		return

	var color := _get_creature_color()

	# Draw creature circle
	VisualHelpers.draw_agent(_visual, color, size)

	# Draw energy bar if low
	if energy < 50.0:
		var energy_progress := energy / 100.0
		var bar_color := Color(0.0, 1.0, 0.0) if energy > 30.0 else Color(1.0, 0.0, 0.0)
		VisualHelpers.draw_progress_bar(_visual, Vector2(0, -size - 8), Vector2(size * 2, 3), energy_progress, bar_color)


## Gets creature color based on type and state.
func _get_creature_color() -> Color:
	if is_dead:
		return Color(0.3, 0.3, 0.3)

	match creature_type:
		CreatureType.HERBIVORE:
			return Color(0.3, 0.8, 0.3)  # Green
		CreatureType.PREDATOR:
			return Color(0.8, 0.2, 0.2)  # Red
		CreatureType.SCAVENGER:
			return Color(0.7, 0.5, 0.2)  # Brown

	return Color.WHITE


## Detects nearby creatures within range.
func detect_creatures_in_range(range_distance: float, type_filter: CreatureType = CreatureType.HERBIVORE) -> Array[CreatureAgent]:
	var detected: Array[CreatureAgent] = []
	var ecosystem := actor.get_parent() as Node

	if not ecosystem or not ecosystem.has_method("get_all_creatures"):
		return detected

	var all_creatures: Array = ecosystem.get_all_creatures()

	for creature in all_creatures:
		if creature == self or not is_instance_valid(creature):
			continue

		var creature_agent := creature as CreatureAgent
		if not creature_agent or creature_agent.is_dead:
			continue

		# Type filter
		if type_filter >= 0 and creature_agent.creature_type != type_filter:
			continue

		# Range check
		var distance: float = actor.global_position.distance_to(creature_agent.actor.global_position)
		if distance <= range_distance:
			detected.append(creature_agent)

	return detected


## Moves toward a target position.
func move_toward(target_pos: Vector2, delta: float) -> float:
	if not actor is Node2D:
		return 0.0

	var current_pos: Vector2 = actor.global_position
	var direction: Vector2 = (target_pos - current_pos).normalized()
	var distance: float = current_pos.distance_to(target_pos)
	var move_amount: float = move_speed * delta

	if distance > move_amount:
		actor.global_position += direction * move_amount
		return distance
	else:
		actor.global_position = target_pos
		return 0.0
