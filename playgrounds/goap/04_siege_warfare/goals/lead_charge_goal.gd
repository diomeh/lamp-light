## Goal: Lead charge into battle.
extends GOAPGoal
class_name LeadChargeGoal

func _init() -> void:
	goal_name = &"LeadCharge"
	priority = 15.0
	desired_state = {&"leading_charge": true}

func is_relevant(state: Dictionary[StringName, Variant]) -> bool:
	return state.get(&"battle_engaged", false) as bool

func is_achieved(state: Dictionary[StringName, Variant]) -> bool:
	return state.get(&"leading_charge", false) as bool
