## Action: Scavenge corpse for food (scavenger).
##
## Eats from corpse to restore energy.
extends GOAPAction
class_name ScavengeCorpseAction

var _scavenge_duration: float = 3.0
var _scavenge_timer: float = 0.0


func _init() -> void:
	action_name = &"ScavengeCorpse"
	cost = 1.5
	preconditions = {&"at_corpse": true}
	effects = {&"energy": 85}


func can_execute(state: Dictionary[StringName, Variant]) -> bool:
	var at_corpse := state.get(&"at_corpse", false) as bool
	var energy_value := state.get(&"energy", 50.0) as float
	return at_corpse and energy_value < 85.0


func enter(_agent: GOAPAgent) -> void:
	_scavenge_timer = 0.0


func execute(agent: GOAPAgent, delta: float) -> ExecResult:
	_scavenge_timer += delta

	var creature := agent as CreatureAgent
	if creature:
		# Restore energy while scavenging
		creature.eat(delta * 20.0)  # 20 energy per second

		# Notify ecosystem to remove corpse portion
		var ecosystem := creature.actor.get_parent() as Node
		var corpse_pos := agent.blackboard.get_value(&"corpse_position", Vector2.ZERO) as Vector2
		if ecosystem and ecosystem.has_method("consume_corpse"):
			ecosystem.consume_corpse(corpse_pos, delta * 10.0)

	if _scavenge_timer >= _scavenge_duration or (creature and creature.energy >= 85.0):
		agent.blackboard.set_value(&"at_corpse", false)
		return ExecResult.SUCCESS

	return ExecResult.RUNNING


func exit(_agent: GOAPAgent) -> void:
	_scavenge_timer = 0.0
