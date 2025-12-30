class_name GOAPState
extends Resource

## Base class that defines all basic interactions over a dictionary.
## Any blackboard or state class should extend this class to provide
## consistent state management with different semantic purposes.

## Internal dictionary for state storage.
## Use set_value/get_value/has_value methods to interact with this.
var _data: Dictionary[String, Variant] = {}

## Signal emitted when any state variable changes.
## Parameters: key (String), new_value (Variant), old_value (Variant)
signal value_changed(key: String, new_value: Variant, old_value: Variant)


func _init() -> void:
	# TODO: implement a sane init logic for state
	# Consider that state may represent an agent's blackboard
	# Or some form of shared stated between agents (WorldState)
	initialize()


## Defines default values that will be used to initialize storage.
func initialize() -> void:
	pass


## Sets a state variable to a specific value.
## Emits value_changed signal if the value actually changed.
func set_value(key: String, value: Variant) -> void:
	var old_value: Variant = _data.get(key)
	_data[key] = value
	if old_value != value:
		value_changed.emit(key, value, old_value)


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
## Emits value_changed signal.
func remove_value(key: String) -> bool:
	if not _data.has(key):
		return false

	var old = _data.get(key)
	_data.erase(key)
	value_changed.emit(key, null, old)
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
## Use with caution - typically used for loading saved states.
func set_state_dict(new_data: Dictionary[String, Variant]) -> void:
	_data = new_data.duplicate()
	value_changed.emit("", null, null)


## Clears all state variables.
## Emits value_changed signal.
func clear() -> void:
	_data.clear()
	value_changed.emit("", null, null)


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
