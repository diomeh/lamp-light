## Infantry unit - melee combat, shield wall formation.
##
## Primary front-line fighters with formation capabilities.
extends UnitAgent
class_name Infantry


func _init() -> void:
	super._init()
	unit_type = UnitType.INFANTRY
	max_health = 120.0
	health = 120.0
	attack_damage = 15.0
	attack_range = 20.0
	attack_cooldown = 1.0
	move_speed = 50.0
	size = 7.0


func _ready() -> void:
	_setup_goals()
	_setup_actions()
	super._ready()


## Sets up infantry goals.
func _setup_goals() -> void:
	goals = [
		MaintainFormationGoal.new(),
		EngageCombatGoal.new(),
		AdvanceGoal.new()
	]


## Sets up infantry actions.
func _setup_actions() -> void:
	actions = [
		MoveToFormationAction.new(),
		AttackEnemyAction.new(),
		AdvanceForwardAction.new(),
		DefendPositionAction.new()
	]
