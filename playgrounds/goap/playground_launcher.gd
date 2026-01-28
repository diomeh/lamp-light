## Playground launcher menu.
##
## Provides a simple UI to select and launch different GOAP playground scenarios.
extends Control

## Playground scenes.
const PLAYGROUNDS := {
	"01_village_economy": {
		"title": "1. Village Resource Economy",
		"description": "Multi-agent resource sharing and survival needs",
		"complexity": "Simple",
		"agents": "5-15",
		"scene": "res://playgrounds/goap/01_village_economy/village_economy.tscn"
	},
	"02_ecosystem": {
		"title": "2. Ecosystem Simulation",
		"description": "Predator-prey dynamics and environmental interaction",
		"complexity": "Simple-Medium",
		"agents": "20-30",
		"scene": "res://playgrounds/goap/02_ecosystem/ecosystem.tscn"
	},
	"03_crafting_factory": {
		"title": "3. Crafting Chain Factory",
		"description": "Deep action chains and multi-stage production",
		"complexity": "Medium-Advanced",
		"agents": "3-12",
		"scene": "res://playgrounds/goap/03_crafting_factory/crafting_factory.tscn"
	},
	"04_siege_warfare": {
		"title": "4. Siege Warfare",
		"description": "Large-scale orchestration and performance stress test",
		"complexity": "Advanced",
		"agents": "50-100",
		"scene": "res://playgrounds/goap/04_siege_warfare/siege_warfare.tscn"
	}
}

var _buttons: Array[Button] = []


func _ready() -> void:
	_create_ui()


## Creates the launcher UI.
func _create_ui() -> void:
	# Title
	var title := Label.new()
	title.text = "GOAP Playground Scenarios"
	title.add_theme_font_size_override("font_size", 24)
	title.anchor_left = 0.5
	title.anchor_top = 0.1
	title.anchor_right = 0.5
	title.anchor_bottom = 0.1
	title.offset_left = -200
	title.offset_right = 200
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	# Description
	var desc := Label.new()
	desc.text = "Interactive demonstrations of GOAP system capabilities"
	desc.anchor_left = 0.5
	desc.anchor_top = 0.15
	desc.anchor_right = 0.5
	desc.anchor_bottom = 0.15
	desc.offset_left = -250
	desc.offset_right = 250
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(desc)

	# Playground buttons
	var y_offset := 0.25
	for key in PLAYGROUNDS.keys():
		var pg = PLAYGROUNDS[key]
		_create_playground_button(pg, y_offset)
		y_offset += 0.15


## Creates a button for a playground scenario.
func _create_playground_button(playground: Dictionary, y_offset: float) -> void:
	var button := Button.new()
	button.text = playground["title"]
	button.anchor_left = 0.5
	button.anchor_top = y_offset
	button.anchor_right = 0.5
	button.anchor_bottom = y_offset
	button.offset_left = -200
	button.offset_right = 200
	button.offset_top = -20
	button.offset_bottom = 20

	# Check if scene exists
	if not ResourceLoader.exists(playground["scene"]):
		button.text += " [NOT IMPLEMENTED]"
		button.disabled = true

	button.pressed.connect(_on_playground_selected.bind(playground["scene"]))
	add_child(button)
	_buttons.append(button)

	# Info label
	var info := Label.new()
	info.text = "%s | %s | %s agents" % [
		playground["description"],
		playground["complexity"],
		playground["agents"]
	]
	info.anchor_left = 0.5
	info.anchor_top = y_offset + 0.04
	info.anchor_right = 0.5
	info.anchor_bottom = y_offset + 0.04
	info.offset_left = -250
	info.offset_right = 250
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 10)
	info.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	add_child(info)


## Handles playground selection.
func _on_playground_selected(scene_path: String) -> void:
	if ResourceLoader.exists(scene_path):
		get_tree().change_scene_to_file(scene_path)
	else:
		push_error("Playground scene not found: %s" % scene_path)
