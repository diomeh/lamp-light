## Predator creature - hunts herbivores when hungry, rests when full.
##
## Behavior pattern: Hunt → Rest → Patrol
extends CreatureAgent
class_name Predator


func _init() -> void:
	super._init()
	creature_type = CreatureType.PREDATOR
	max_lifespan = 150.0
	reproduction_threshold = 85.0
	move_speed = 120.0  # Faster than herbivores
	size = 10.0
	energy = 70.0


func _ready() -> void:
	_setup_goals()
	_setup_actions()
	super._ready()

	if _visual:
		_visual.draw.connect(_on_visual_draw)


func _process(delta: float) -> void:
	super._process(delta)

	if is_dead:
		return

	# Detect nearby prey
	_detect_prey()


## Sets up predator goals.
func _setup_goals() -> void:
	goals = [
		HuntGoal.new(),         # Hunt when hungry
		RestGoal.new(),         # Rest when full
		PatrolGoal.new()        # Wander when neutral
	]


## Sets up predator actions.
func _setup_actions() -> void:
	actions = [
		HuntHerbivoreAction.new(),
		RestAction.new(),
		PatrolAction.new()
	]


## Detects nearby herbivores for hunting.
func _detect_prey() -> void:
	var herbivores := detect_creatures_in_range(100.0, CreatureType.HERBIVORE)

	if herbivores.size() > 0:
		# Find closest herbivore
		var closest: CreatureAgent = null
		var closest_dist := INF

		for herb in herbivores:
			var dist: float = actor.global_position.distance_to(herb.actor.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest = herb

		target_creature = closest
		blackboard.set_value(&"prey_detected", true)
		blackboard.set_value(&"prey_distance", closest_dist)
	else:
		target_creature = null
		blackboard.set_value(&"prey_detected", false)
		blackboard.set_value(&"prey_distance", 1000.0)
