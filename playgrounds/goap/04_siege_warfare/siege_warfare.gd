## Siege Warfare playground scene controller.
##
## Demonstrates large-scale GOAP orchestration (50-100 agents),[br]
## frame budgeting, and formation-based AI.
extends PlaygroundBase

## Army configuration.
@export_group("Armies")
@export var attacker_infantry: int = 20
@export var attacker_archers: int = 10
@export var attacker_siege: int = 2
@export var attacker_commanders: int = 1

@export var defender_infantry: int = 15
@export var defender_archers: int = 8
@export var defender_commanders: int = 1

## Performance.
@export_group("Performance")
@export var frame_budget_ms: float = 5.0

## Units.
var _units: Array[Node2D] = []
var _attacker_units: Array[UnitAgent] = []
var _defender_units: Array[UnitAgent] = []

## Performance tracking.
var _performance_dashboard_visible: bool = false
var _plans_this_frame: int = 0
var _frame_time: float = 0.0


func _ready() -> void:
	super._ready()
	_spawn_armies()


func _process(_delta: float) -> void:
	if is_paused:
		return

	var frame_start := Time.get_ticks_usec()

	# Update unit targeting
	_update_unit_targets()

	# Track performance
	_frame_time = (Time.get_ticks_usec() - frame_start) / 1000.0
	_plans_this_frame = 0

	# Update visuals
	queue_redraw()

	# Update debug metrics
	if debug_overlay and debug_overlay.visible:
		update_debug_metrics(_calculate_metrics())


func _unhandled_input(event: InputEvent) -> void:
	super._unhandled_input(event)

	# Tab - Toggle performance dashboard
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		_performance_dashboard_visible = !_performance_dashboard_visible
		get_viewport().set_input_as_handled()


func _draw() -> void:
	# Draw battlefield elements
	_draw_wall()

	# Draw performance dashboard if enabled
	if _performance_dashboard_visible:
		_draw_performance_dashboard()

	# Units draw themselves


## Spawns both armies.
func _spawn_armies() -> void:
	# Spawn attackers
	_spawn_army(UnitAgent.Army.ATTACKER, attacker_infantry, attacker_archers, attacker_siege, attacker_commanders)

	# Spawn defenders
	_spawn_army(UnitAgent.Army.DEFENDER, defender_infantry, defender_archers, 0, defender_commanders)


## Spawns an army.
func _spawn_army(army: UnitAgent.Army, infantry_count: int, archer_count: int, siege_count: int, commander_count: int) -> void:
	var spawn_area := Rect2(100, 200, 200, 200) if army == UnitAgent.Army.ATTACKER else Rect2(700, 200, 200, 200)

	var army_units: Array[UnitAgent] = []

	# Spawn infantry
	for i in range(infantry_count):
		var unit: UnitAgent = _spawn_unit(UnitAgent.UnitType.INFANTRY, army, spawn_area)
		if unit:
			army_units.append(unit)

	# Spawn archers
	for i in range(archer_count):
		var unit: UnitAgent = _spawn_unit(UnitAgent.UnitType.ARCHER, army, spawn_area)
		if unit:
			army_units.append(unit)

	# Spawn siege operators
	for i in range(siege_count):
		var unit: UnitAgent = _spawn_unit(UnitAgent.UnitType.SIEGE_OPERATOR, army, spawn_area)
		if unit:
			army_units.append(unit)

	# Spawn commanders
	for i in range(commander_count):
		var commander: Commander = _spawn_unit(UnitAgent.UnitType.COMMANDER, army, spawn_area) as Commander
		if commander:
			# Assign troops to commander
			for unit in army_units:
				commander.add_commanded_unit(unit)
			army_units.append(commander)

	# Store army reference
	if army == UnitAgent.Army.ATTACKER:
		_attacker_units = army_units
	else:
		_defender_units = army_units


## Spawns a single unit.
func _spawn_unit(unit_type: UnitAgent.UnitType, army: UnitAgent.Army, spawn_area: Rect2) -> UnitAgent:
	var actor := Node2D.new()
	actor.position = Vector2(
		randf_range(spawn_area.position.x, spawn_area.position.x + spawn_area.size.x),
		randf_range(spawn_area.position.y, spawn_area.position.y + spawn_area.size.y)
	)
	add_child(actor)

	var agent: UnitAgent

	match unit_type:
		UnitAgent.UnitType.INFANTRY:
			actor.name = "Infantry%d" % _units.size()
			agent = Infantry.new()
		UnitAgent.UnitType.ARCHER:
			actor.name = "Archer%d" % _units.size()
			agent = Archer.new()
		UnitAgent.UnitType.SIEGE_OPERATOR:
			actor.name = "Siege%d" % _units.size()
			agent = SiegeOperator.new()
		UnitAgent.UnitType.COMMANDER:
			actor.name = "Commander%d" % _units.size()
			agent = Commander.new()

	if agent:
		agent.name = "UnitAgent"
		agent.army = army
		actor.add_child(agent)
		_units.append(actor)
		register_agent(agent)

	return agent


## Updates unit targeting (detect enemies).
func _update_unit_targets() -> void:
	for unit_actor in _units:
		if not is_instance_valid(unit_actor):
			continue

		var agent := unit_actor.get_node_or_null("UnitAgent") as UnitAgent
		if not agent or agent.is_dead:
			continue

		# Detect enemies
		var enemies := agent.detect_enemies_in_range(100.0)

		if enemies.size() > 0:
			# Find closest enemy
			var closest: UnitAgent = enemies[0]
			var closest_dist: float = agent.actor.global_position.distance_to(closest.actor.global_position)

			for enemy in enemies:
				var dist: float = agent.actor.global_position.distance_to(enemy.actor.global_position)
				if dist < closest_dist:
					closest_dist = dist
					closest = enemy

			agent.target_enemy = closest
			agent.blackboard.set_value(&"has_target", true)

			# For archers - check if enemies in melee range
			if agent.unit_type == UnitAgent.UnitType.ARCHER:
				var melee_enemies := agent.detect_enemies_in_range(30.0)
				agent.blackboard.set_value(&"enemies_in_melee_range", melee_enemies.size())
		else:
			agent.target_enemy = null
			agent.blackboard.set_value(&"has_target", false)
			agent.blackboard.set_value(&"enemies_in_melee_range", 0)


## Called when a unit dies.
func _on_unit_died(unit: UnitAgent) -> void:
	if not unit or not is_instance_valid(unit):
		return

	# Remove after delay
	await get_tree().create_timer(1.0).timeout

	if is_instance_valid(unit) and is_instance_valid(unit.actor):
		_units.erase(unit.actor)
		unregister_agent(unit)
		unit.actor.queue_free()


## Gets all living units.
func get_all_units() -> Array:
	var living: Array = []
	for unit_actor in _units:
		if is_instance_valid(unit_actor):
			var agent := unit_actor.get_node_or_null("UnitAgent") as UnitAgent
			if agent and not agent.is_dead:
				living.append(agent)
	return living


## Draws the defensive wall.
func _draw_wall() -> void:
	var wall_rect := Rect2(Vector2(480, 200), Vector2(40, 200))
	draw_rect(wall_rect, Color(0.4, 0.4, 0.4, 0.8))
	draw_rect(wall_rect, Color.WHITE, false, 3.0)

	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(485, 190), "WALL", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)


## Draws performance dashboard.
func _draw_performance_dashboard() -> void:
	var dashboard_rect := Rect2(Vector2(50, 50), Vector2(250, 150))
	draw_rect(dashboard_rect, Color(0.1, 0.1, 0.1, 0.9))

	var font := ThemeDB.fallback_font
	var y_offset := 70

	draw_string(font, Vector2(60, y_offset), "PERFORMANCE DASHBOARD", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
	y_offset += 25

	# FPS
	draw_string(font, Vector2(60, y_offset), "FPS: %d" % Performance.get_monitor(Performance.TIME_FPS), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	y_offset += 20

	# Frame time
	var frame_color := Color.GREEN if _frame_time < frame_budget_ms else Color.RED
	draw_string(font, Vector2(60, y_offset), "Frame: %.2fms / %.2fms" % [_frame_time, frame_budget_ms], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, frame_color)
	y_offset += 20

	# Active units
	draw_string(font, Vector2(60, y_offset), "Active Units: %d" % get_all_units().size(), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	y_offset += 20

	# Army counts
	var attacker_count := 0
	var defender_count := 0
	for unit in get_all_units():
		if unit is UnitAgent:
			if unit.army == UnitAgent.Army.ATTACKER:
				attacker_count += 1
			else:
				defender_count += 1

	draw_string(font, Vector2(60, y_offset), "Attackers: %d | Defenders: %d" % [attacker_count, defender_count], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)


## Calculates metrics for debug display.
func _calculate_metrics() -> Dictionary:
	var metrics := {}

	var attacker_count := 0
	var defender_count := 0
	for unit in get_all_units():
		if unit is UnitAgent:
			if unit.army == UnitAgent.Army.ATTACKER:
				attacker_count += 1
			else:
				defender_count += 1

	metrics["Attackers"] = attacker_count
	metrics["Defenders"] = defender_count
	metrics["Total Units"] = get_all_units().size()
	metrics["Frame Time"] = "%.2fms" % _frame_time

	return metrics


## Resets the scenario.
func _reset_scenario() -> void:
	super._reset_scenario()

	# Remove all units
	for unit in _units:
		if is_instance_valid(unit):
			unit.queue_free()
	_units.clear()
	_attacker_units.clear()
	_defender_units.clear()
	agents.clear()

	# Respawn armies
	_spawn_armies()
