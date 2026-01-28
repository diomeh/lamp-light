## Action: Deposit resources at the stockpile.
##
## Requires being at stockpile with resources.[br]
## Contributes to community resources.
extends GOAPAction
class_name DepositResourcesAction

var _deposit_timer: float = 0.0
var _deposit_duration: float = 1.5


func _init() -> void:
	action_name = &"DepositResources"
	cost = 1.5
	preconditions = {
		&"at_location": &"stockpile"
	}
	effects = {
		&"contributed": true,
		&"has_food": false,
		&"has_water": false,
		&"has_wood": false
	}


func can_execute(state: Dictionary[StringName, Variant]) -> bool:
	# Need to be at stockpile with at least one resource
	var at_stockpile: bool = state.get(&"at_location") == &"stockpile"
	var has_any_resource: bool = (
		state.get(&"has_food", false) or
		state.get(&"has_water", false) or
		state.get(&"has_wood", false)
	)
	return at_stockpile and has_any_resource


func enter(_agent: GOAPAgent) -> void:
	_deposit_timer = 0.0


func execute(agent: GOAPAgent, delta: float) -> ExecResult:
	_deposit_timer += delta

	if _deposit_timer >= _deposit_duration:
		# Deposit complete
		var villager := agent as VillagerAgent
		if villager:
			# Add resources to shared stockpile
			var village_economy := villager.actor.get_parent() as Node
			if village_economy and village_economy.has_method("_setup_shared_state"):
				# Access shared blackboard
				if village_economy.get("_shared_blackboard"):
					var shared_bb: GOAPState = village_economy._shared_blackboard

					if villager.has_food:
						var current := shared_bb.get_value(&"stockpile_food", 0) as int
						shared_bb.set_value(&"stockpile_food", current + 1)
						villager.has_food = false

					if villager.has_water:
						var current := shared_bb.get_value(&"stockpile_water", 0) as int
						shared_bb.set_value(&"stockpile_water", current + 1)
						villager.has_water = false

					if villager.has_wood:
						var current := shared_bb.get_value(&"stockpile_wood", 0) as int
						shared_bb.set_value(&"stockpile_wood", current + 1)
						villager.has_wood = false

			# Update agent blackboard
			agent.blackboard.set_value(&"has_food", false)
			agent.blackboard.set_value(&"has_water", false)
			agent.blackboard.set_value(&"has_wood", false)
			agent.blackboard.set_value(&"contributed", true)

		return ExecResult.SUCCESS

	return ExecResult.RUNNING


func exit(_agent: GOAPAgent) -> void:
	_deposit_timer = 0.0
