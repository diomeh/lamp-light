## Action: Deposit finished product to storage.
##
## Transfers product from inventory to storage.
extends GOAPAction
class_name DepositProductAction

var _deposit_timer: float = 0.0
var _deposit_duration: float = 1.5


func _init() -> void:
	action_name = &"DepositProduct"
	cost = 2.0
	preconditions = {}
	effects = {}


func can_execute(state: Dictionary[StringName, Variant]) -> bool:
	# Can deposit if have any product
	for product in [&"iron_ingot", &"tool", &"gear", &"machine"]:
		if state.get(product, 0) as int > 0:
			return true
	return false


func enter(_agent: GOAPAgent) -> void:
	_deposit_timer = 0.0


func execute(agent: GOAPAgent, delta: float) -> ExecResult:
	var crafter := agent as CrafterAgent
	if not crafter:
		return ExecResult.FAILURE

	var factory := crafter.actor.get_parent() as Node
	if not factory or not factory.has_method("get_storage_position"):
		return ExecResult.FAILURE

	# Move to storage
	var storage_pos: Vector2 = factory.get_storage_position()
	var distance := crafter.move_toward(storage_pos, delta)

	if distance < 20.0:
		# At storage - deposit
		_deposit_timer += delta

		if _deposit_timer >= _deposit_duration:
			# Deposit all products
			for product in [&"machine", &"gear", &"tool", &"iron_ingot"]:
				var amount := crafter.inventory.get(product, 0) as int
				if amount > 0:
					if factory.has_method("add_to_storage"):
						factory.add_to_storage(product, amount)
					crafter.remove_material(product, amount)

			return ExecResult.SUCCESS

	return ExecResult.RUNNING


func exit(_agent: GOAPAgent) -> void:
	_deposit_timer = 0.0
