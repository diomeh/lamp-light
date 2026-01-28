## Action: Repair damaged equipment.
extends GOAPAction
class_name RepairEquipmentAction

func _init() -> void:
	action_name = &"RepairEquipment"
	cost = 4.0
	preconditions = {}
	effects = {&"equipment_repaired": true}

func execute(_agent: GOAPAgent, _delta: float) -> ExecResult:
	return ExecResult.SUCCESS
