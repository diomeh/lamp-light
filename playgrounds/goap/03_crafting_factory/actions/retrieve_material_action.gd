## Action: Retrieve material from storage.
##
## Gets materials needed for crafting from storage.
extends GOAPAction
class_name RetrieveMaterialAction

var _material: StringName
var _amount: int
var _retrieve_timer: float = 0.0
var _retrieve_duration: float = 1.5


func _init(mat: StringName = &"iron_ingot", qty: int = 1) -> void:
	_material = mat
	_amount = qty
	action_name = StringName("Retrieve_%s" % mat)
	cost = 2.0
	preconditions = {}
	effects = {mat: qty}


func can_execute(state: Dictionary[StringName, Variant]) -> bool:
	var space := state.get(&"inventory_space", 0) as int
	return space >= _amount


func enter(_agent: GOAPAgent) -> void:
	_retrieve_timer = 0.0


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
		# At storage - retrieve
		_retrieve_timer += delta

		if _retrieve_timer >= _retrieve_duration:
			# Try to retrieve from storage
			if factory.has_method("retrieve_from_storage"):
				if factory.retrieve_from_storage(_material, _amount):
					crafter.add_material(_material, _amount)
					return ExecResult.SUCCESS
			return ExecResult.FAILURE

	return ExecResult.RUNNING


func exit(_agent: GOAPAgent) -> void:
	_retrieve_timer = 0.0
