## Herbivore creature - grazes on grass and flees from predators.
##
## Behavior pattern: Graze → Flee (if threatened) → Reproduce (if well-fed)
extends CreatureAgent
class_name Herbivore


func _init() -> void:
	super._init()
	creature_type = CreatureType.HERBIVORE
	max_lifespan = 100.0
	reproduction_threshold = 75.0
	move_speed = 100.0
	size = 7.0
	energy = 60.0


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

	# Detect nearby predators for fleeing
	_detect_threats()


## Sets up herbivore goals.
func _setup_goals() -> void:
	goals = [
		FleeGoal.new(),         # Highest priority when threatened
		GrazeGoal.new(),        # Primary behavior
		ReproduceGoal.new()     # When well-fed
	]


## Sets up herbivore actions.
func _setup_actions() -> void:
	actions = [
		FleeFromPredatorAction.new(),
		GrazeGrassAction.new(),
		ReproduceAction.new()
	]


## Detects nearby predators and updates blackboard.
func _detect_threats() -> void:
	var predators := detect_creatures_in_range(80.0, CreatureType.PREDATOR)

	if predators.size() > 0:
		# Find closest predator
		var closest: CreatureAgent = null
		var closest_dist := INF

		for pred in predators:
			var dist: float = actor.global_position.distance_to(pred.actor.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest = pred

		detected_threat = closest
		blackboard.set_value(&"threat_detected", true)
		blackboard.set_value(&"threat_distance", closest_dist)
	else:
		detected_threat = null
		blackboard.set_value(&"threat_detected", false)
		blackboard.set_value(&"threat_distance", 1000.0)
