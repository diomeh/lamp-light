## Crafting Chain Factory playground scene controller.
##
## Demonstrates deep action chain planning, multi-stage dependencies,[br]
## and just-in-time production through GOAP.
extends PlaygroundBase

## Crafter configuration.
@export_group("Crafters")
@export var crafter_count: int = 6

## Order configuration.
@export_group("Orders")
@export var auto_generate_orders: bool = true
@export var order_interval: float = 10.0

## Crafter actors.
var _crafters: Array[Node2D] = []

## Crafting stations by type.
var _stations: Dictionary = {}

## Active orders (product -> quantity).
var _active_orders: Dictionary = {}

## Completed products in storage.
var _storage: Dictionary = {
	&"ore": 0,
	&"wood": 0,
	&"iron_ingot": 0,
	&"tool": 0,
	&"gear": 0,
	&"machine": 0
}

## Material source locations.
var _material_sources: Dictionary = {}

## Order generation timer.
var _order_timer: float = 0.0

## Sankey diagram display toggle.
var _show_diagram: bool = false

## Production tracking for diagram.
var _production_flow: Dictionary = {}


func _ready() -> void:
	super._ready()

	_setup_stations()
	_setup_material_sources()
	_spawn_crafters()
	_generate_initial_order()


func _process(delta: float) -> void:
	if is_paused:
		return

	# Auto-generate orders
	if auto_generate_orders:
		_order_timer += delta
		if _order_timer >= order_interval:
			_order_timer = 0.0
			_generate_random_order()

	# Update visuals
	queue_redraw()

	# Update debug metrics
	if debug_overlay and debug_overlay.visible:
		update_debug_metrics(_calculate_metrics())


func _unhandled_input(event: InputEvent) -> void:
	super._unhandled_input(event)

	# D - Toggle Sankey diagram
	if event is InputEventKey and event.pressed and event.keycode == KEY_D:
		_show_diagram = !_show_diagram
		get_viewport().set_input_as_handled()


func _draw() -> void:
	# Draw material sources
	_draw_material_sources()

	# Draw storage area
	_draw_storage()

	# Draw Sankey diagram if enabled
	if _show_diagram:
		_draw_sankey_diagram()

	# Stations and crafters draw themselves


## Sets up crafting stations.
func _setup_stations() -> void:
	_stations = {
		&"mine": [],
		&"forest": [],
		&"furnace": [],
		&"workshop": [],
		&"factory": [],
		&"assembly": []
	}

	# Mine (ore extraction) - 2 stations
	for i in range(2):
		var station := CraftingStation.new()
		station.station_type = &"mine"
		station.position = Vector2(100, 100 + i * 60)
		add_child(station)
		_stations[&"mine"].append(station)

	# Forest (wood gathering) - 2 stations
	for i in range(2):
		var station := CraftingStation.new()
		station.station_type = &"forest"
		station.position = Vector2(100, 300 + i * 60)
		add_child(station)
		_stations[&"forest"].append(station)

	# Furnace (ore → ingot) - 2 stations
	for i in range(2):
		var station := CraftingStation.new()
		station.station_type = &"furnace"
		station.position = Vector2(300, 150 + i * 60)
		add_child(station)
		_stations[&"furnace"].append(station)

	# Workshop (ingot + wood → tool) - 2 stations
	for i in range(2):
		var station := CraftingStation.new()
		station.station_type = &"workshop"
		station.position = Vector2(500, 150 + i * 60)
		add_child(station)
		_stations[&"workshop"].append(station)

	# Factory (ingot + tool → gear) - 2 stations
	for i in range(2):
		var station := CraftingStation.new()
		station.station_type = &"factory"
		station.position = Vector2(700, 150 + i * 60)
		add_child(station)
		_stations[&"factory"].append(station)

	# Assembly (gear + tool → machine) - 1 station (bottleneck)
	var assembly := CraftingStation.new()
	assembly.station_type = &"assembly"
	assembly.position = Vector2(900, 180)
	add_child(assembly)
	_stations[&"assembly"].append(assembly)


## Sets up material source locations.
func _setup_material_sources() -> void:
	_material_sources = {
		&"ore": Vector2(100, 130),
		&"wood": Vector2(100, 330)
	}


## Spawns initial crafters.
func _spawn_crafters() -> void:
	for i in range(crafter_count):
		_spawn_crafter(i)


## Spawns a single crafter.
func _spawn_crafter(index: int) -> void:
	var actor := Node2D.new()
	actor.name = "Crafter%d" % index
	actor.position = Vector2(200 + index * 40, 400)
	add_child(actor)

	var agent := CrafterAgent.new()
	agent.name = "CrafterAgent"
	actor.add_child(agent)

	_crafters.append(actor)
	register_agent(agent)


## Generates initial order.
func _generate_initial_order() -> void:
	_active_orders[&"machine"] = 1


## Generates random order.
func _generate_random_order() -> void:
	var products := [&"iron_ingot", &"tool", &"gear", &"machine"]
	var product: StringName = products[randi() % products.size()]
	var quantity := randi_range(1, 3)

	if _active_orders.has(product):
		_active_orders[product] += quantity
	else:
		_active_orders[product] = quantity


## Finds available station of type.
func find_available_station(station_type: StringName) -> CraftingStation:
	if not _stations.has(station_type):
		return null

	var stations: Array = _stations[station_type]
	for station in stations:
		if station is CraftingStation and station.is_available():
			return station

	return null


## Gets material source position.
func get_material_source_position(mat: StringName) -> Vector2:
	return _material_sources.get(mat, Vector2.ZERO)


## Gets storage position.
func get_storage_position() -> Vector2:
	return Vector2(900, 400)


## Adds product to storage.
func add_to_storage(product: StringName, amount: int) -> void:
	_storage[product] = _storage.get(product, 0) + amount

	# Check if order fulfilled
	if _active_orders.has(product):
		var needed: int = _active_orders[product]
		var fulfilled := mini(amount, needed)
		_active_orders[product] -= fulfilled

		if _active_orders[product] <= 0:
			_active_orders.erase(product)

	# Track production flow
	_production_flow[product] = _production_flow.get(product, 0) + amount


## Retrieves material from storage.
func retrieve_from_storage(mat: StringName, amount: int) -> bool:
	if _storage.get(mat, 0) >= amount:
		_storage[mat] -= amount
		return true
	return false


## Draws material sources.
func _draw_material_sources() -> void:
	for mat in _material_sources:
		var pos: Vector2 = _material_sources[mat]
		draw_circle(pos, 20, Color(0.6, 0.4, 0.2, 0.5))

		var font := ThemeDB.fallback_font
		draw_string(font, pos + Vector2(0, -25), str(mat), HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color.WHITE)


## Draws storage area.
func _draw_storage() -> void:
	var storage_pos := get_storage_position()
	var rect := Rect2(storage_pos - Vector2(40, 40), Vector2(80, 80))
	draw_rect(rect, Color(0.3, 0.5, 0.3, 0.5))
	draw_rect(rect, Color.WHITE, false, 2.0)

	var font := ThemeDB.fallback_font
	draw_string(font, storage_pos + Vector2(0, -45), "STORAGE", HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color.WHITE)


## Draws Sankey diagram.
func _draw_sankey_diagram() -> void:
	var diagram_rect := Rect2(Vector2(50, 500), Vector2(300, 150))
	draw_rect(diagram_rect, Color(0.1, 0.1, 0.1, 0.9))

	var font := ThemeDB.fallback_font
	draw_string(font, diagram_rect.position + Vector2(10, 20), "Production Flow", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)

	# Simple bar chart of production
	var y_offset := 40
	for product in [&"iron_ingot", &"tool", &"gear", &"machine"]:
		var count := _production_flow.get(product, 0) as int
		var bar_width := minf(count * 20.0, 250.0)

		var bar_pos := diagram_rect.position + Vector2(10, y_offset)
		draw_rect(Rect2(bar_pos, Vector2(bar_width, 15)), Color(0.2, 0.6, 0.8))
		draw_string(font, bar_pos + Vector2(0, -3), "%s: %d" % [product, count], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)

		y_offset += 25


## Calculates metrics for debug display.
func _calculate_metrics() -> Dictionary:
	var metrics := {}

	metrics["Crafters"] = _crafters.size()
	metrics["Active Orders"] = _active_orders.size()

	# Storage levels
	for product in _storage:
		metrics["Storage_%s" % product] = _storage[product]

	# Station occupancy
	var total_stations := 0
	var occupied_stations := 0
	for station_type in _stations:
		var stations: Array = _stations[station_type]
		total_stations += stations.size()
		for station in stations:
			if station is CraftingStation and station.occupied_by:
				occupied_stations += 1

	metrics["Station Occupancy"] = "%d/%d" % [occupied_stations, total_stations]

	return metrics


## Resets the scenario.
func _reset_scenario() -> void:
	super._reset_scenario()

	# Remove all crafters
	for crafter in _crafters:
		if is_instance_valid(crafter):
			crafter.queue_free()
	_crafters.clear()
	agents.clear()

	# Reset orders and storage
	_active_orders.clear()
	_production_flow.clear()
	for product in _storage:
		_storage[product] = 0

	# Release all stations
	for station_type in _stations:
		var stations: Array = _stations[station_type]
		for station in stations:
			if station is CraftingStation:
				station.release()

	# Respawn crafters
	_spawn_crafters()
	_generate_initial_order()
