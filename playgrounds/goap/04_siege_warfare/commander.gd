## Commander unit - assigns formations, issues orders.
##
## Leadership unit that coordinates other units via shared blackboard.
extends UnitAgent
class_name Commander


## Units under command.
var commanded_units: Array[UnitAgent] = []


func _init() -> void:
	super._init()
	unit_type = UnitType.COMMANDER
	max_health = 150.0
	health = 150.0
	attack_damage = 20.0
	attack_range = 30.0
	attack_cooldown = 1.2
	move_speed = 55.0
	size = 9.0


func _ready() -> void:
	_setup_goals()
	_setup_actions()
	super._ready()


## Sets up commander goals.
func _setup_goals() -> void:
	goals = [
		CommandTroopsGoal.new(),
		LeadChargeGoal.new(),
		TacticalRetreatGoal.new()
	]


## Sets up commander actions.
func _setup_actions() -> void:
	actions = [
		AssignFormationAction.new(),
		IssueAdvanceAction.new(),
		IssueRetreatAction.new(),
		LeadByExampleAction.new()
	]


## Assigns unit to command.
func add_commanded_unit(unit: UnitAgent) -> void:
	if unit and unit not in commanded_units:
		commanded_units.append(unit)


## Removes unit from command.
func remove_commanded_unit(unit: UnitAgent) -> void:
	commanded_units.erase(unit)


## Gets units in command.
func get_commanded_units() -> Array[UnitAgent]:
	# Clean up dead/invalid units
	var valid_units: Array[UnitAgent] = []
	for unit in commanded_units:
		if is_instance_valid(unit) and not unit.is_dead:
			valid_units.append(unit)
	commanded_units = valid_units
	return commanded_units
