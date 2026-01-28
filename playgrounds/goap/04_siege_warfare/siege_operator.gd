## Siege Operator - operates siege equipment, defends machinery.
##
## Specialized unit for breaching walls and operating catapults.
extends UnitAgent
class_name SiegeOperator


func _init() -> void:
	super._init()
	unit_type = UnitType.SIEGE_OPERATOR
	max_health = 90.0
	health = 90.0
	attack_damage = 8.0
	attack_range = 25.0
	attack_cooldown = 2.0
	move_speed = 40.0  # Slower
	size = 6.0


func _ready() -> void:
	_setup_goals()
	_setup_actions()
	super._ready()


## Sets up siege operator goals.
func _setup_goals() -> void:
	goals = [
		OperateSiegeGoal.new(),
		DefendEquipmentGoal.new()
	]


## Sets up siege operator actions.
func _setup_actions() -> void:
	actions = [
		OperateCatapultAction.new(),
		DefendSiegeAction.new(),
		RepairEquipmentAction.new()
	]
