## Scavenger creature - eats corpses, socializes when satisfied.
##
## Behavior pattern: Find Corpse → Scavenge → Socialize
extends CreatureAgent
class_name Scavenger


func _init() -> void:
	super._init()
	creature_type = CreatureType.SCAVENGER
	max_lifespan = 120.0
	reproduction_threshold = 80.0
	move_speed = 90.0
	size = 6.0
	energy = 55.0


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

	# Detect nearby corpses
	_detect_corpses()


## Sets up scavenger goals.
func _setup_goals() -> void:
	goals = [
		ScavengeGoal.new(),     # Find food from corpses
		SocializeGoal.new()     # Group up when satisfied
	]


## Sets up scavenger actions.
func _setup_actions() -> void:
	actions = [
		FindCorpseAction.new(),
		ScavengeCorpseAction.new(),
		SocializeAction.new()
	]


## Detects nearby corpses for scavenging.
func _detect_corpses() -> void:
	var ecosystem := actor.get_parent() as Node

	if not ecosystem or not ecosystem.has_method("get_corpses"):
		blackboard.set_value(&"corpse_detected", false)
		return

	var corpses: Array = ecosystem.get_corpses()

	if corpses.size() > 0:
		# Find closest corpse
		var closest: Vector2 = Vector2.ZERO
		var closest_dist := INF

		for corpse_pos in corpses:
			var dist: float = actor.global_position.distance_to(corpse_pos)
			if dist < closest_dist:
				closest_dist = dist
				closest = corpse_pos

		blackboard.set_value(&"corpse_detected", true)
		blackboard.set_value(&"corpse_position", closest)
		blackboard.set_value(&"corpse_distance", closest_dist)
	else:
		blackboard.set_value(&"corpse_detected", false)
