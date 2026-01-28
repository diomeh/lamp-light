## Base unit agent for the Siege Warfare playground.
##
## Shared functionality for all military units (infantry, archers, siege, commanders).[br]
## Demonstrates large-scale GOAP coordination (50-100 agents).
class_name UnitAgent
extends GOAPAgent

## Unit type enumeration.
enum UnitType {
	INFANTRY,
	ARCHER,
	SIEGE_OPERATOR,
	COMMANDER
}

## Army affiliation.
enum Army {
	ATTACKER,
	DEFENDER
}

## This unit's type.
var unit_type: UnitType = UnitType.INFANTRY

## This unit's army.
var army: Army = Army.ATTACKER

## Visual representation.
var _visual: Node2D

## Combat stats.
var health: float = 100.0
var max_health: float = 100.0
var attack_damage: float = 10.0
var attack_range: float = 30.0
var attack_cooldown: float = 1.5
var _attack_timer: float = 0.0

## Movement.
var move_speed: float = 60.0

## Formation.
var formation_position: Vector2 = Vector2.ZERO
var in_formation: bool = false
var commander: UnitAgent = null

## Combat targets.
var target_enemy: UnitAgent = null
var target_structure: Node = null

## Unit size for visual/collision.
var size: float = 6.0

## Is unit dead.
var is_dead: bool = false


func _init() -> void:
	super._init()


func _ready() -> void:
	super._ready()  # Must be first to set actor
	_initialize_blackboard()
	_create_visual()


func _process(delta: float) -> void:
	if is_dead:
		return

	# Update attack cooldown
	if _attack_timer > 0.0:
		_attack_timer -= delta


## Initializes unit blackboard state.
func _initialize_blackboard() -> void:
	blackboard.set_value(&"health", health)
	blackboard.set_value(&"army", int(army))
	blackboard.set_value(&"in_formation", in_formation)
	blackboard.set_value(&"has_target", false)
	blackboard.set_value(&"can_attack", true)
	blackboard.set_value(&"is_dead", false)


## Creates visual representation.
func _create_visual() -> void:
	_visual = Node2D.new()
	_visual.name = "Visual"
	actor.add_child(_visual)
	_visual.draw.connect(_on_visual_draw)


## Draws the unit.
func _on_visual_draw() -> void:
	if not _visual or is_dead:
		return

	var color := _get_unit_color()

	# Draw unit circle
	VisualHelpers.draw_agent(_visual, color, size)

	# Draw health bar if damaged
	if health < max_health:
		var health_progress := health / max_health
		var bar_color := Color(0.0, 1.0, 0.0) if health > 50.0 else Color(1.0, 0.0, 0.0)
		VisualHelpers.draw_progress_bar(_visual, Vector2(0, -size - 8), Vector2(size * 2, 3), health_progress, bar_color)

	# Draw formation indicator if in formation
	if in_formation:
		_visual.draw_circle(Vector2.ZERO, size * 1.3, Color(1.0, 1.0, 1.0, 0.2))


## Gets unit color based on army and type.
func _get_unit_color() -> Color:
	if is_dead:
		return Color(0.3, 0.3, 0.3)

	var base_color: Color

	match unit_type:
		UnitType.INFANTRY:
			base_color = Color(0.5, 0.5, 0.8)  # Blue
		UnitType.ARCHER:
			base_color = Color(0.5, 0.8, 0.5)  # Green
		UnitType.SIEGE_OPERATOR:
			base_color = Color(0.8, 0.5, 0.2)  # Orange
		UnitType.COMMANDER:
			base_color = Color(0.9, 0.8, 0.2)  # Gold

	# Darken for attackers, brighten for defenders
	if army == Army.ATTACKER:
		return base_color.darkened(0.3)
	else:
		return base_color.lightened(0.2)


## Takes damage from an attack.
func take_damage(amount: float) -> void:
	if is_dead:
		return

	health = maxf(health - amount, 0.0)
	blackboard.set_value(&"health", health)

	if health <= 0.0:
		die()


## Kills this unit.
func die() -> void:
	if is_dead:
		return

	is_dead = true
	blackboard.set_value(&"is_dead", true)
	abort()  # Stop current plan

	# Notify battlefield
	var battlefield := actor.get_parent() as Node
	if battlefield and battlefield.has_method("_on_unit_died"):
		battlefield._on_unit_died(self)


## Attacks a target unit.
func attack_unit(target: UnitAgent) -> bool:
	if _attack_timer > 0.0 or not target or target.is_dead:
		return false

	var distance: float = actor.global_position.distance_to(target.actor.global_position)
	if distance <= attack_range:
		target.take_damage(attack_damage)
		_attack_timer = attack_cooldown
		return true

	return false


## Moves toward a target position.
func move_toward(target_pos: Vector2, delta: float, speed_multiplier: float = 1.0) -> float:
	if not actor is Node2D:
		return 0.0

	var current_pos: Vector2 = actor.global_position
	var direction: Vector2 = (target_pos - current_pos).normalized()
	var distance: float = current_pos.distance_to(target_pos)
	var move_amount: float = move_speed * speed_multiplier * delta

	if distance > move_amount:
		actor.global_position += direction * move_amount
		return distance
	else:
		actor.global_position = target_pos
		return 0.0


## Detects nearby enemies within range.
func detect_enemies_in_range(range_distance: float) -> Array[UnitAgent]:
	var detected: Array[UnitAgent] = []
	var battlefield := actor.get_parent() as Node

	if not battlefield or not battlefield.has_method("get_all_units"):
		return detected

	var all_units: Array = battlefield.get_all_units()

	for unit in all_units:
		if not is_instance_valid(unit) or unit == self:
			continue

		var unit_agent := unit as UnitAgent
		if not unit_agent or unit_agent.is_dead or unit_agent.army == army:
			continue

		var distance: float = actor.global_position.distance_to(unit_agent.actor.global_position)
		if distance <= range_distance:
			detected.append(unit_agent)

	return detected


## Sets formation assignment.
func assign_formation(pos: Vector2, cmd: UnitAgent) -> void:
	formation_position = pos
	commander = cmd
	in_formation = false
	blackboard.set_value(&"formation_position", pos)
	blackboard.set_value(&"has_formation", true)


## Enters formation.
func enter_formation() -> void:
	in_formation = true
	blackboard.set_value(&"in_formation", true)


## Breaks formation.
func break_formation() -> void:
	in_formation = false
	blackboard.set_value(&"in_formation", false)
