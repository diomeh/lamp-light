## Archer unit - ranged combat, fall back when pressured.
##
## Long-range support with tactical repositioning.
extends UnitAgent
class_name Archer


func _init() -> void:
	super._init()
	unit_type = UnitType.ARCHER
	max_health = 80.0
	health = 80.0
	attack_damage = 12.0
	attack_range = 80.0  # Long range!
	attack_cooldown = 1.8
	move_speed = 55.0
	size = 6.0


func _ready() -> void:
	_setup_goals()
	_setup_actions()
	super._ready()


## Sets up archer goals.
func _setup_goals() -> void:
	goals = [
		FallBackGoal.new(),          # Retreat when enemies close
		RangedAttackGoal.new(),
		MaintainDistanceGoal.new()
	]


## Sets up archer actions.
func _setup_actions() -> void:
	actions = [
		FallBackAction.new(),
		RangedAttackAction.new(),
		RepositionAction.new()
	]
