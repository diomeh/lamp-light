class_name GOAPState
extends Resource

## Base class that defines all basic interactions over a dictionary.
## Any blackboard or state class should extend this class to provide
## consistent state management with different semantic purposes.

## Internal dictionary for state storage.
## Use set_value/get_value/has_value methods to interact with this.
var _data: Dictionary[String, Variant] = {}


## Creates a new GOAPState instance.
## A raw Dictionary can be passed to be used as initial data.
func _init(state: Dictionary[String, Variant] = {}):
	initialize(state)


## Virtual function to set initial data.
## By default will append given entries into interal data store.
func initialize(state: Dictionary[String, Variant]) -> void:
	append_raw(state)


## Sets a state variable to a specific value.
func set_value(key: String, value: Variant) -> void:
	var old_value: Variant = _data.get(key)
	if old_value != value:
		_data[key] = value


## Gets a state variable value.
## Returns the value if it exists, otherwise returns the default value.
func get_value(key: String, default: Variant = null) -> Variant:
	return _data.get(key, default)


## Checks if a state variable exists.
## Returns true if the key exists, false otherwise.
func has_value(key: String) -> bool:
	return _data.has(key)


## Removes a state variable.
## Returns true if the key existed and was removed, false if it didn't exist.
func remove_value(key: String) -> bool:
	if not _data.has(key):
		return false

	_data.erase(key)
	return true


## Returns a copy of the entire state dictionary.
## Useful for planning, simulation, debugging, or serialization.
func get_state_copy() -> Dictionary[String, Variant]:
	return _data.duplicate()


## Returns a reference to the state dictionary.
## Use with care as it will break things if modified, best for read-only operations.
func get_state_ref() -> Dictionary[String, Variant]:
	return _data


## Replaces the entire state dictionary with a new one.
## Use with caution as this requires a deep copy - typically used for loading saved states.
func set_state_dict(new_data: Dictionary[String, Variant]) -> void:
	_data = new_data.duplicate(true)


## Clears all state variables.
func clear() -> void:
	_data.clear()


## Checks if all key-value pairs in the conditions dictionary match the current state.
## Returns true if all conditions are met, false otherwise.
func matches_conditions(conditions: Dictionary[String, Variant]) -> bool:
	for key in conditions:
		if not _data.has(key) or _data[key] != conditions[key]:
			return false
	return true


## Checks if all entries in given state are present and equal to current state
## Returns true on success, false otherwise
func matches_state(state: GOAPState) -> bool:
	return matches_conditions(state.get_state_ref())


## Applies a set of effects (changes) to the state.
## Each key-value pair in effects will update the corresponding state variable.
func apply_effects(effects: Dictionary[String, Variant]) -> void:
	for key in effects:
		set_value(key, effects[key])


## Helper method to increment a numeric value.
## If the key doesn't exist, it's initialized to 0 before incrementing.
## If key holds a value that is neither float or int, execution is aborted.
func increment(key: String, amount: float = 1.0) -> void:
	var current = get_value(key, 0.0)

	# Prevent adding incompatible types
	if typeof(current) not in [TYPE_INT, TYPE_FLOAT]:
		return

	set_value(key, current + amount)


## Helper method to decrement a numeric value.
## If the key doesn't exist, it's initialized to 0 before decrementing.
## If key holds a value that is neither float or int, execution is aborted.
func decrement(key: String, amount: float = 1.0) -> void:
	increment(key, amount * -1)


## Helper method to append a raw dictionary to state's internal data.
## New entries will be created and existing entries will be overriden.
func append_raw(state: Dictionary[String, Variant]) -> void:
	if state.is_empty():
		return

	_data.merge(state, true)


## Helper method to append an existing state data to this state's internal data.
## New entries will be created and existing entries will be overriden.
func append(state: GOAPState) -> void:
	append_raw(state.get_state_ref())


## Merges two states into a new state.
## If entries from a and b collide, b entries will take precedence.
static func merge(a: GOAPState, b: GOAPState) -> GOAPState:
	var s = GOAPState.new()
	s.append(a)
	s.append(b)
	return s
