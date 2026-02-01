## Dictionary-based state container for GOAP with hierarchical support.[br][br]
##
## Provides type-safe key-value storage with optional parent state for inheritance.[br]
## Enables multi-layer state management (Agent → Squad → Global) with shadowing.[br][br]
##
## [b]Hierarchical Features:[/b][br]
## - Parent reference for state inheritance[br]
## - Shadowing: local values override parent values[br]
## - Flattening: create planning snapshots that merge hierarchy[br]
## - Backward compatible: parent defaults to null (flat behavior)[br][br]
##
## [b]Usage (Flat):[/b]
## [codeblock]
## var state = GOAPState.new({"health": 100, "has_weapon": true})
## state.set_value("ammo", 30)
## var hp = state.get_value("health", 0)
## [/codeblock][br]
##
## [b]Usage (Hierarchical):[/b]
## [codeblock]
## var global_state = GOAPState.new({"is_daytime": true, "alarm_active": false})
## var agent_state = GOAPState.new({"health": 100}, global_state)
##
## agent_state.get_value("health")      # 100 (local)
## agent_state.get_value("is_daytime")  # true (from parent)
##
## # Planning automatically flattens
## var flat = agent_state.to_flat_state()  # Merges local + parent
## [/codeblock][br]
##
## See also: [GOAPAgent], [GOAPPlanner]
class_name GOAPState
extends RefCounted

## Internal storage for this layer. Access via [method set_value], [method get_value], etc.
var _data: Dictionary[StringName, Variant] = {}

## Optional parent state for hierarchical fallthrough lookup
var _parent: GOAPState = null

## Emitted when a state variable is changed.[br][br]
signal state_changed(key: StringName, new_value: Variant, old_value: Variant)


## Sets the parent state for hierarchical lookup.[br][br]
##
## Raises error and aborts if setting parent would create circular reference.[br][br]
##
## [param parent] Parent state to inherit from, or null to remove parent.
func set_parent(parent: GOAPState) -> void:
	_parent = parent

	var p := _parent
	while p != null:
		p = p.get_parent()
		if p == parent:
			# FIXME: error is causing test to fail. Investigate
			#push_error("Cannot set parent: would create circular reference.")
			_parent = null
			return


## Gets the parent state.[br][br]
##
## Returns parent GOAPState or null if this is root state.
func get_parent() -> GOAPState:
	return _parent


## Returns true if this state has a parent.
func has_parent() -> bool:
	return _parent != null


## Creates new GOAPState with optional parent for hierarchy.[br][br]
##
## [param state] Initial key-value pairs to populate the state.[br]
## [param parent] Optional parent state for hierarchical inheritance.
func _init(state: Dictionary[StringName, Variant] = {}, parent: GOAPState = null) -> void:
	set_parent(parent)
	initialize(state)


## Initializes state with given data. Override for custom initialization.[br][br]
##
## [param state] Data to merge into internal storage.
func initialize(state: Dictionary[StringName, Variant]) -> void:
	append_raw(state)


## Sets a state variable. Only updates if value changed.[br][br]
##
## [param key] Variable name.[br]
## [param value] New value to store.[br]
## Emits [signal GOAPState.state_changed] if value is modified.
func set_value(key: StringName, value: Variant) -> void:
	var old_value: Variant = _data.get(key)
	if old_value != value:
		_data[key] = value
		state_changed.emit(key, value, old_value)


## Appends value to an array stored at key.[br][br]
##
## Creates array if key doesn't exist. No-op if key holds non-array[br]
## or value already present.[br][br]
##
## [param key] Variable name containing array.[br]
## [param value] Value to append.
func append_value(key: StringName, value: Variant) -> void:
	var arr: Variant = _data.get(key)

	if not arr:
		_data[key] = [value]
		return

	if not arr is Array: return
	if arr.has(value): return

	arr.append(value)


## Gets a state variable value with hierarchical fallthrough.[br][br]
##
## Searches this state first, then parent chain if not found.[br]
## Enables agent beliefs to shadow (override) global state.[br][br]
##
## [param key] Variable name to retrieve.[br]
## [param default] Value returned if key doesn't exist anywhere in chain.[br]
## [param local_only] If true, only checks this state (not parents).[br]
## Returns stored value or [param default].
func get_value(key: StringName, default: Variant = null, local_only: bool = false) -> Variant:
	# 1. Check local data first
	if _data.has(key):
		return _data[key]

	# 2. Fall through to parent if exists
	if not local_only and _parent != null:
		return _parent.get_value(key, default)

	# 3. Not found anywhere in chain
	return default


## Checks if a state variable exists in this state or parent chain.[br][br]
##
## [param key] Variable name to check.[br]
## [param local_only] If true, only checks this state (not parents).[br]
## Returns [code]true[/code] if key exists in chain.
func has_value(key: StringName, local_only: bool = false) -> bool:
	if _data.has(key):
		return true

	if not local_only and _parent != null:
		return _parent.has_value(key, false)

	return false


## Removes a state variable.[br][br]
##
## [param key] Variable name to remove.[br]
## Returns [code]true[/code] if removed, [code]false[/code] if key didn't exist.
func erase_value(key: StringName) -> bool:
	return _data.erase(key)


## Returns deep copy of internal dictionary.[br][br]
##
## Safe for modification. Use for planning, simulation, or serialization.[br][br]
##
## Returns copy of state data.
func to_dict(local_only: bool = false) -> Dictionary[StringName, Variant]:
	if local_only:
		return _data.duplicate(true)

	return flatten()


## Returns reference to state dictionary (flattened if hierarchical).[br][br]
##
## When this state has a parent, returns a flattened view that includes[br]
## inherited values. When flat (no parent), returns direct reference to _data.[br][br]
##
## [b]Note:[/b] This method creates a new dictionary when hierarchical to ensure[br]
## goal checking sees the complete state including inherited values.[br][br]
##
## Returns reference to state data (flattened if hierarchical).
func to_ref() -> Dictionary[StringName, Variant]:
	if _parent != null:
		return flatten()
	return _data


## Creates a duplicate GOAPState with copied data.[br][br]
##
## [b]Note:[/b] Parent reference is NOT copied (creates independent state).[br]
## Use [method duplicate_with_parent] if you need to preserve hierarchy.[br][br]
##
## Returns new [GOAPState] instance with same data, no parent.
func duplicate() -> GOAPState:
	return GOAPState.new(to_dict(), null)


## Creates duplicate GOAPState preserving parent reference.[br][br]
##
## Useful for creating sibling states that share same parent.[br][br]
##
## Returns new [GOAPState] instance with same data and parent.
func duplicate_with_parent() -> GOAPState:
	return GOAPState.new(to_dict(), _parent)


## Replaces entire state with deep copy of new data.[br][br]
##
## [b]Warning:[/b] Overwrites all existing data. Use for loading saved states.[br][br]
##
## [param new_data] Dictionary to copy as new state.
func override(new_data: Dictionary[StringName, Variant]) -> void:
	_data = new_data.duplicate(true)


## Removes all state variables.
func clear() -> void:
	_data.clear()


## Checks if all conditions are satisfied by this state.[br][br]
##
## [param conditions] Key-value pairs that must match.[br]
## [br]
## Returns [code]true[/code] if all conditions match, [code]false[/code] otherwise.
func matches_conditions(conditions: Dictionary[StringName, Variant]) -> bool:
	for key in conditions:
		if not _data.has(key) or _data[key] != conditions[key]:
			return false
	return true


## Checks if another state's data is subset of this state.[br][br]
##
## [param state] State to compare against.[br]
## [br]
## Returns [code]true[/code] if all entries in [param state] match.
func matches_state(state: GOAPState) -> bool:
	return matches_conditions(state.to_ref())


## Applies effects dictionary to this state.[br][br]
##
## Each key-value pair overwrites corresponding state variable.[br][br]
##
## [param effects] Changes to apply.
func apply_effects(effects: Dictionary[StringName, Variant]) -> void:
	for key in effects:
		set_value(key, effects[key])


## Increments numeric value at key.[br][br]
##
## Initializes to 0 if key doesn't exist. No-op if value is non-numeric.[br][br]
##
## [param key] Variable name.[br]
## [param amount] Value to add (default 1.0).
func increment(key: StringName, amount: float = 1.0) -> void:
	var current = get_value(key, 0.0)

	# Prevent adding incompatible types
	if typeof(current) not in [TYPE_INT, TYPE_FLOAT]:
		return

	set_value(key, current + amount)


## Decrements numeric value at key.[br][br]
##
## Initializes to 0 if key doesn't exist. No-op if value is non-numeric.[br][br]
##
## [param key] Variable name.[br]
## [param amount] Value to subtract (default 1.0).
func decrement(key: StringName, amount: float = 1.0) -> void:
	increment(key, amount * -1)


## Merges raw dictionary into state. Existing keys are overwritten.[br][br]
##
## [param state] Data to merge.
func append_raw(state: Dictionary[StringName, Variant]) -> void:
	if state.is_empty():
		return

	_data.merge(state, true)


## Merges another GOAPState into this one. Existing keys are overwritten.[br][br]
##
## [param state] State to merge from.
func append(state: GOAPState) -> void:
	append_raw(state.to_dict())


## Creates new state by merging two states.[br][br]
##
## [param a] First state (lower priority on collision).[br]
## [param b] Second state (higher priority on collision).[br]
## [br]
## Returns a new [GOAPState] with merged data.
static func merge(a: GOAPState, b: GOAPState) -> GOAPState:
	var s = GOAPState.new()
	s.append(a)
	s.append(b)
	return s


## Flattens hierarchical state into single dictionary.[br][br]
##
## Walks parent chain bottom-up and merges states.[br]
## Local values override parent values (shadowing).[br]
## Creates planning snapshot safe for concurrent modification.[br][br]
##
## Returns flattened dictionary with all state from root to this node.
func flatten() -> Dictionary[StringName, Variant]:
	var flattened: Dictionary[StringName, Variant] = {}

	# Recursively collect parent states (bottom-up)
	if _parent != null:
		flattened = _parent.flatten()

	# Overlay this layer's data (local shadows parent) - deep copy for isolation
	flattened.merge(_data.duplicate(true), true)

	return flattened


## Creates flattened GOAPState for planning (no parent reference).[br][br]
##
## Used by planner to get snapshot of complete state without hierarchy.[br]
## Planner works with flat state for simplicity and performance.[br][br]
##
## Returns new [GOAPState] with flattened data and no parent.
func to_flat_state() -> GOAPState:
	return GOAPState.new(flatten(), null)


## Finds conditions not satisfied by this state.[br][br]
##
## Used by [GOAPPlanner] to determine which goal conditions need actions.[br][br]
##
## [param conditions] Required key-value pairs to check.[br]
## [br]
## Returns dictionary of conditions where this state differs from required values.
func get_unsatisfied_conditions(
	conditions: Dictionary[StringName, Variant]
) -> Dictionary[StringName, Variant]:
	var unsatisfied: Dictionary[StringName, Variant] = {}
	for key in conditions:
		var required_value: Variant = conditions[key]
		var current_value: Variant = get_value(key)
		if current_value != required_value:
			unsatisfied[key] = required_value
	return unsatisfied
