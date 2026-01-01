## Dictionary-based state container for GOAP world state and blackboards.
##
## Provides type-safe key-value storage with helper methods for common operations.[br]
## Used for both shared world state and per-agent blackboards.[br][br]
##
## [b]Usage:[/b]
## [codeblock]
## var state = GOAPState.new({"health": 100, "has_weapon": true})
## state.set_value("ammo", 30)
## var hp = state.get_value("health", 0)
## [/codeblock][br]
##
## See also:[br]
## [GOAPAgent][br]
## [GOAPPlanner][br]
class_name GOAPState
extends Resource

## Internal storage. Access via [method set_value], [method get_value], etc.
var _data: Dictionary[String, Variant] = {}


## Creates new GOAPState, optionally initialized with data.[br][br]
##
## [param state] Initial key-value pairs to populate the state.
func _init(state: Dictionary[String, Variant]={}):
	initialize(state)


## Initializes state with given data. Override for custom initialization.[br][br]
##
## [param state] Data to merge into internal storage.
func initialize(state: Dictionary[String, Variant]) -> void:
	append_raw(state)


## Sets a state variable. Only updates if value changed.[br][br]
##
## [param key] Variable name.[br]
## [param value] New value to store.
func set_value(key: String, value: Variant) -> void:
	var old_value: Variant = _data.get(key)
	if old_value != value:
		_data[key] = value


## Appends value to an array stored at key.[br][br]
##
## Creates array if key doesn't exist. No-op if key holds non-array
## or value already present.[br][br]
##
## [param key] Variable name containing array.[br]
## [param value] Value to append.
func append_value(key: String, value: Variant) -> void:
	var arr: Variant = _data.get(key)

	if not arr:
		_data[key] = [value]
		return

	if not arr is Array: return
	if arr.has(value): return

	arr.append(value)


## Gets a state variable value.[br][br]
##
## [param key] Variable name to retrieve.[br]
## [param default] Value returned if key doesn't exist.[br]
## Returns stored value or [param default].
func get_value(key: String, default: Variant = null) -> Variant:
	return _data.get(key, default)


## Checks if a state variable exists.[br][br]
##
## [param key] Variable name to check.[br]
## Returns [code]true[/code] if key exists.
func has_value(key: String) -> bool:
	return _data.has(key)


## Removes a state variable.[br][br]
##
## [param key] Variable name to remove.[br]
## Returns [code]true[/code] if removed, [code]false[/code] if key didn't exist.
func remove_value(key: String) -> bool:
	if not _data.has(key):
		return false

	_data.erase(key)
	return true


## Returns shallow copy of internal dictionary.[br][br]
##
## Safe for modification. Use for planning, simulation, or serialization.[br][br]
##
## Returns copy of state data.
func get_state_copy() -> Dictionary[String, Variant]:
	return _data.duplicate()


## Returns direct reference to internal dictionary.[br][br]
##
## [b]Warning:[/b] Modifications will affect this state. Use for read-only access.[br][br]
##
## Returns reference to internal data.
func get_state_ref() -> Dictionary[String, Variant]:
	return _data


## Replaces entire state with deep copy of new data.[br][br]
##
## [b]Warning:[/b] Overwrites all existing data. Use for loading saved states.[br][br]
##
## [param new_data] Dictionary to copy as new state.
func set_state_dict(new_data: Dictionary[String, Variant]) -> void:
	_data = new_data.duplicate(true)


## Removes all state variables.
func clear() -> void:
	_data.clear()


## Checks if all conditions are satisfied by this state.[br][br]
##
## [param conditions] Key-value pairs that must match.[br]
## Returns [code]true[/code] if all conditions match, [code]false[/code] otherwise.
func matches_conditions(conditions: Dictionary[String, Variant]) -> bool:
	for key in conditions:
		if not _data.has(key) or _data[key] != conditions[key]:
			return false
	return true


## Checks if another state's data is subset of this state.[br][br]
##
## [param state] State to compare against.[br]
## Returns [code]true[/code] if all entries in [param state] match.
func matches_state(state: GOAPState) -> bool:
	return matches_conditions(state.get_state_ref())


## Applies effects dictionary to this state.[br][br]
##
## Each key-value pair overwrites corresponding state variable.[br][br]
##
## [param effects] Changes to apply.
func apply_effects(effects: Dictionary[String, Variant]) -> void:
	for key in effects:
		set_value(key, effects[key])


## Increments numeric value at key.[br][br]
##
## Initializes to 0 if key doesn't exist. No-op if value is non-numeric.[br][br]
##
## [param key] Variable name.[br]
## [param amount] Value to add (default 1.0).
func increment(key: String, amount: float = 1.0) -> void:
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
func decrement(key: String, amount: float = 1.0) -> void:
	increment(key, amount * -1)


## Merges raw dictionary into state. Existing keys are overwritten.[br][br]
##
## [param state] Data to merge.
func append_raw(state: Dictionary[String, Variant]) -> void:
	if state.is_empty():
		return

	_data.merge(state, true)


## Merges another GOAPState into this one. Existing keys are overwritten.[br][br]
##
## [param state] State to merge from.
func append(state: GOAPState) -> void:
	append_raw(state.get_state_ref())


## Creates new state by merging two states.[br][br]
##
## [param a] First state (lower priority on collision).[br]
## [param b] Second state (higher priority on collision).[br]
## Returns a new [GOAPState] with merged data.
static func merge(a: GOAPState, b: GOAPState) -> GOAPState:
	var s = GOAPState.new()
	s.append(a)
	s.append(b)
	return s


## Finds conditions not satisfied by this state.[br][br]
##
## Used by [GOAPPlanner] to determine which goal conditions need actions.[br][br]
##
## [param conditions] Required key-value pairs to check.[br]
## Returns a dictionary of conditions where this state differs from required values[br].
func get_unsatisfied_conditions(
	conditions: Dictionary[String, Variant]
) -> Dictionary[String, Variant]:
	var unsatisfied: Dictionary[String, Variant] = {}
	for key in conditions:
		var required_value: Variant = conditions[key]
		var current_value: Variant = get_value(key)
		if current_value != required_value:
			unsatisfied[key] = required_value
	return unsatisfied
