## Visual helpers for GOAP playground rendering.
##
## Provides utility functions for drawing shapes, labels, and debug visualizations[br]
## using minimal resources (no sprites required).[br][br]
##
## [b]Usage:[/b]
## [codeblock]
## func _draw() -> void:
##     VisualHelpers.draw_agent(self, Color.BLUE, 10.0)
##     VisualHelpers.draw_label(self, "Gathering", Vector2(0, -20))
## [/codeblock]
class_name VisualHelpers
extends Object

## Common colors for playground elements.
class Colors:
	const AGENT_IDLE := Color(0.5, 0.5, 0.5)
	const AGENT_PLANNING := Color(1.0, 1.0, 0.0)
	const AGENT_PERFORMING := Color(0.0, 1.0, 0.0)
	const AGENT_FAILED := Color(1.0, 0.0, 0.0)
	const AGENT_SELECTED := Color(0.0, 0.8, 1.0)

	const RESOURCE_FOOD := Color(0.8, 0.4, 0.2)
	const RESOURCE_WATER := Color(0.2, 0.4, 0.8)
	const RESOURCE_WOOD := Color(0.6, 0.3, 0.1)

	const LOCATION_NEUTRAL := Color(0.7, 0.7, 0.7, 0.3)
	const LOCATION_ACTIVE := Color(0.3, 0.8, 0.3, 0.5)

	const DEBUG_PATH := Color(1.0, 1.0, 1.0, 0.3)
	const DEBUG_TEXT := Color(1.0, 1.0, 1.0)


## Draws a circular agent representation.
## [param node] Node2D to draw on (use self in _draw).[br]
## [param color] Agent color.[br]
## [param radius] Agent radius.[br]
## [param position] Local position (default: Vector2.ZERO).
static func draw_agent(
	node: Node2D,
	color: Color,
	radius: float = 10.0,
	position: Vector2 = Vector2.ZERO
) -> void:
	node.draw_circle(position, radius, color)
	# Draw outline
	node.draw_arc(position, radius, 0, TAU, 32, Colors.DEBUG_TEXT, 1.0)


## Draws an agent with state-based coloring.
## [param node] Node2D to draw on.[br]
## [param agent] GOAP agent to visualize.[br]
## [param radius] Agent radius.[br]
## [param is_selected] Whether agent is selected.
static func draw_agent_state(
	node: Node2D,
	agent: GOAPAgent,
	radius: float = 10.0,
	is_selected: bool = false
) -> void:
	var color := Colors.AGENT_IDLE

	if is_selected:
		color = Colors.AGENT_SELECTED
	else:
		match agent.get_state():
			GOAPAgent.State.IDLE:
				color = Colors.AGENT_IDLE
			GOAPAgent.State.PLANNING:
				color = Colors.AGENT_PLANNING
			GOAPAgent.State.PERFORMING:
				color = Colors.AGENT_PERFORMING

	draw_agent(node, color, radius)


## Draws a text label at a position.
## [param node] Node2D to draw on.[br]
## [param text] Text to display.[br]
## [param position] Local position.[br]
## [param color] Text color.[br]
## [param size] Font size (approximate).
static func draw_label(
	node: Node2D,
	text: String,
	position: Vector2,
	color: Color = Colors.DEBUG_TEXT,
	size: int = 12
) -> void:
	# Note: Godot 4's draw_string requires a font
	# For simplicity, we'll use a default font from theme
	var font := ThemeDB.fallback_font
	var font_size := size
	node.draw_string(font, position, text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, color)


## Draws a resource node (circle with icon).
## [param node] Node2D to draw on.[br]
## [param resource_type] Type of resource ("food", "water", "wood").[br]
## [param position] Local position.[br]
## [param radius] Resource node radius.
static func draw_resource(
	node: Node2D,
	resource_type: String,
	position: Vector2,
	radius: float = 15.0
) -> void:
	var color := Colors.RESOURCE_FOOD

	match resource_type.to_lower():
		"food":
			color = Colors.RESOURCE_FOOD
		"water":
			color = Colors.RESOURCE_WATER
		"wood":
			color = Colors.RESOURCE_WOOD

	node.draw_circle(position, radius, color)
	node.draw_arc(position, radius, 0, TAU, 32, Colors.DEBUG_TEXT, 2.0)

	# Draw simple icon (letter)
	var icon := resource_type.substr(0, 1).to_upper()
	draw_label(node, icon, position + Vector2(0, 5), Colors.DEBUG_TEXT, 14)


## Draws a location zone (rectangle).
## [param node] Node2D to draw on.[br]
## [param rect] Rectangle bounds.[br]
## [param color] Zone color.[br]
## [param filled] Whether to fill the rectangle.
static func draw_location_zone(
	node: Node2D,
	rect: Rect2,
	color: Color = Colors.LOCATION_NEUTRAL,
	filled: bool = true
) -> void:
	if filled:
		node.draw_rect(rect, color)
	else:
		node.draw_rect(rect, color, false, 2.0)


## Draws a path between points.
## [param node] Node2D to draw on.[br]
## [param points] Array of Vector2 points.[br]
## [param color] Path color.[br]
## [param width] Line width.
static func draw_path(
	node: Node2D,
	points: PackedVector2Array,
	color: Color = Colors.DEBUG_PATH,
	width: float = 2.0
) -> void:
	if points.size() < 2:
		return

	for i in range(points.size() - 1):
		node.draw_line(points[i], points[i + 1], color, width)


## Draws an arrow from start to end.
## [param node] Node2D to draw on.[br]
## [param start] Start position.[br]
## [param end] End position.[br]
## [param color] Arrow color.[br]
## [param width] Line width.
static func draw_arrow(
	node: Node2D,
	start: Vector2,
	end: Vector2,
	color: Color = Colors.DEBUG_TEXT,
	width: float = 2.0
) -> void:
	node.draw_line(start, end, color, width)

	# Draw arrowhead
	var direction := (end - start).normalized()
	var perpendicular := direction.orthogonal()
	var arrow_size := 8.0

	var arrow_left := end - direction * arrow_size + perpendicular * arrow_size * 0.5
	var arrow_right := end - direction * arrow_size - perpendicular * arrow_size * 0.5

	node.draw_line(end, arrow_left, color, width)
	node.draw_line(end, arrow_right, color, width)


## Draws a progress bar.
## [param node] Node2D to draw on.[br]
## [param position] Center position.[br]
## [param size] Bar size (width x height).[br]
## [param progress] Progress value (0.0 to 1.0).[br]
## [param foreground] Progress bar color.[br]
## [param background] Background color.
static func draw_progress_bar(
	node: Node2D,
	position: Vector2,
	size: Vector2,
	progress: float,
	foreground: Color = Color(0.0, 1.0, 0.0),
	background: Color = Color(0.3, 0.3, 0.3)
) -> void:
	var half_size := size * 0.5
	var rect := Rect2(position - half_size, size)

	# Background
	node.draw_rect(rect, background)

	# Progress
	var progress_clamped := clampf(progress, 0.0, 1.0)
	var progress_rect := Rect2(
		rect.position,
		Vector2(rect.size.x * progress_clamped, rect.size.y)
	)
	node.draw_rect(progress_rect, foreground)

	# Border
	node.draw_rect(rect, Colors.DEBUG_TEXT, false, 1.0)


## Draws a need indicator (like hunger/thirst).
## [param node] Node2D to draw on.[br]
## [param position] Position above agent.[br]
## [param need_value] Need value (0-100).[br]
## [param need_name] Name of the need.[br]
## [param critical_threshold] Value at which to show as critical.
static func draw_need_indicator(
	node: Node2D,
	position: Vector2,
	need_value: float,
	need_name: String = "",
	critical_threshold: float = 70.0
) -> void:
	var progress := need_value / 100.0
	var color := Color(0.0, 1.0, 0.0) if need_value < critical_threshold else Color(1.0, 0.0, 0.0)

	draw_progress_bar(node, position, Vector2(30, 5), progress, color)

	if need_name:
		draw_label(node, need_name, position + Vector2(0, -10), Colors.DEBUG_TEXT, 8)


## Gets color for agent based on state.
static func get_agent_state_color(agent: GOAPAgent, is_selected: bool = false) -> Color:
	if is_selected:
		return Colors.AGENT_SELECTED

	match agent.get_state():
		GOAPAgent.State.IDLE:
			return Colors.AGENT_IDLE
		GOAPAgent.State.PLANNING:
			return Colors.AGENT_PLANNING
		GOAPAgent.State.PERFORMING:
			return Colors.AGENT_PERFORMING
		_:
			return Colors.AGENT_IDLE
