## Goal: Rest to restore stamina.
##
## Lower priority than survival needs.[br]
## Only pursued when stamina is low.
extends GOAPGoal
class_name RestGoal


func _init() -> void:
	goal_name = &"Rest"
	priority = 5.0
	desired_state = {&"stamina": 100}


func get_priority(state: Dictionary[StringName, Variant]) -> float:
	var stamina_value := state.get(&"stamina", 100.0) as float
	# Priority increases as stamina decreases
	# 100 stamina = 0 priority, 0 stamina = 5 priority
	return priority * (1.0 - stamina_value / 100.0)


func is_relevant(state: Dictionary[StringName, Variant]) -> bool:
	# Only pursue if stamina is below 40
	var stamina_value := state.get(&"stamina", 100.0) as float
	return stamina_value < 40.0


func is_achieved(state: Dictionary[StringName, Variant]) -> bool:
	# Achieved when stamina is restored above 80
	var stamina_value := state.get(&"stamina", 100.0) as float
	return stamina_value > 80.0
