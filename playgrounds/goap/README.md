# GOAP Playground Scenarios

Interactive demonstration scenes for exploring the GOAP (Goal-Oriented Action Planning)
system through hands-on experimentation.

## Purpose

These playgrounds help developers:

- **Understand** GOAP patterns through realistic game scenarios
- **Explore** system capabilities interactively
- **Learn** by experimentation with adjustable parameters
- **See** emergent behaviors from goal-driven AI

Unlike unit tests (which validate correctness), playgrounds demonstrate **usage patterns** and allow **free exploration**.

---

## Playground Scenarios

### 1. Village Resource Economy

**Genre:** Survival/Simulation | **Complexity:** Simple | **Agents:** 5-15

**What it demonstrates:**

- Multi-agent resource sharing via shared blackboard
- Dynamic goal prioritization based on needs (hunger, thirst)
- Emergent cooperation without explicit teamwork code
- Resource management patterns

**Scenario:**
Villagers balance personal survival needs (hunger, thirst, stamina) with contributing to community stockpiles. Watch emergent behaviors as resource scarcity forces prioritization decisions.

**Key GOAP Elements:**

- **Goals:** SurviveHunger, SurviveThirst, ContributeToStockpile, Rest
- **Actions:** GatherWood, GatherFood, FetchWater, EatFood, Drink, DepositResources, MoveTo
- **State:** Personal (hunger, thirst, stamina, has_resource, at_location) + Shared (stockpiles)

**Interactive Features:**

- Adjust villager count (3-15)
- Control resource spawn rates (abundant → scarce)
- Modify need decay rates (hunger/thirst speed)
- Click villagers to inspect current plan/state
- Toggle debug overlay (F1) for detailed metrics

**Learning Objectives:**

- Understand shared blackboard state for coordination
- See dynamic priority changes based on agent needs
- Observe emergent cooperation patterns
- Learn resource management via GOAP

---

### 2. Ecosystem Simulation

**Genre:** Simulation | **Complexity:** Simple-Medium | **Agents:** 20-30

**What it demonstrates:**

- Predator-prey dynamics from individual goal-driven behaviors
- Environmental interaction (grass depletion/regrowth)
- Emergent population balance
- Reactive behaviors (fleeing high-priority goals)

**Scenario:**
20-30 creatures in a simple ecosystem: herbivores graze and flee predators, predators hunt when hungry and rest when full, scavengers eat corpses. Population balance emerges naturally.

**Creature Types:**

- **Herbivore:** Graze → Flee → Reproduce
- **Predator:** Hunt → Rest → Patrol
- **Scavenger:** Find Corpse → Scavenge → Socialize

**Interactive Features:**

- Adjust population ratios (herbivore:predator:scavenger)
- Control hunger/energy decay rates
- Set reproduction thresholds
- Spawn/remove creatures by species
- View population graphs over time (toggle with G)

**Learning Objectives:**

- See complex ecology emerge from simple goals
- Understand fleeing patterns (high priority interrupts)
- Learn environmental state integration
- Observe population dynamics from individual decisions

---

### 3. Crafting Chain Factory

**Genre:** Automation/Crafting | **Complexity:** Medium-Advanced | **Agents:** 3-12

**What it demonstrates:**

- Deep action chains (5-7 step plans)
- Multi-stage dependency planning
- Just-in-time production from goal priorities
- Resource reservation and station occupancy management
- Deadlock prevention patterns

**Scenario:**
Agents produce complex items through multi-tier crafting chains (ore → ingots → tools → gears → machines). System automatically balances production based on customer demand, creating emergent supply chains.

**Crafting Tiers:**

```plaintext
Raw Ore (mine)
  → Iron Ingot (furnace, 1 ore, 3s)
	→ Tool (workshop, 2 ingots + wood, 5s)
	  → Gear (factory, 5 ingots + 1 tool, 8s)
		→ Machine (assembly, 3 gears + 2 tools, 12s)
```

**Interactive Features:**

- Place custom orders to trigger production
- Disable crafting stations to create bottlenecks
- Adjust agent count (3-12 specialists)
- Modify recipe requirements dynamically
- View Sankey diagram of material flow (toggle with D)

**Learning Objectives:**

- Master deep action chain planning
- See just-in-time production emerge naturally
- Learn resource reservation patterns
- Understand bottleneck detection and handling

---

### 4. Siege Warfare

**Genre:** Strategy/Tactics | **Complexity:** Advanced | **Agents:** 50-100

**What it demonstrates:**

- Large-scale GOAP orchestration (stress test)
- Frame-budgeted scheduling under load
- Formation maintenance via shared blackboard
- Commander-unit hierarchy patterns
- Performance limits and optimization techniques

**Scenario:**
Two armies (attackers vs defenders) with multiple unit types: infantry, archers, siege weapons, commanders. Attackers breach walls while defenders coordinate defense. Units maintain formations and execute tactical maneuvers.

**Unit Types:**

- **Infantry:** Melee combat, shield wall formation
- **Archer:** Ranged volleys, fall back when pressured
- **Siege Operator:** Operate catapults, defend equipment
- **Commander:** Assign formations, issue retreat orders

**Interactive Features:**

- Adjust army sizes (20-100 units per side)
- Control frame budget (2-10ms) - see throttling in action
- Modify wall health and breach points
- Spawn reinforcements dynamically
- Kill commanders to see formation collapse
- Real-time performance dashboard (FPS, plans/frame, budget usage)

**Learning Objectives:**

- Master large-scale orchestration (50-100 agents)
- Understand frame budgeting under stress
- Learn formation-based AI patterns
- See emergent tactics (flanking, retreats)
- Identify and optimize performance limits

---

## Learning Progression

**Recommended Order:**

1. **Village Resource Economy** → Learn multi-agent basics and shared resources
2. **Ecosystem Simulation** → Understand reactive behaviors and emergent patterns
3. **Crafting Chain Factory** → Master deep planning and dependency chains
4. **Siege Warfare** → Stress test and performance optimization

Each playground builds on concepts from previous ones while introducing new patterns.

---

## Common Controls

**All Playgrounds:**

- `F1` - Toggle debug overlay (agent state, plans, metrics)
- `Space` - Pause/Resume simulation
- `R` - Reset scenario to initial state
- `Mouse Click` - Select agent to inspect
- `1/2/5/X` - Time scale (1x, 2x, 5x, 10x)

**Scenario-Specific:**

- `G` - Toggle graphs (Ecosystem: population chart)
- `D` - Toggle diagrams (Crafting: Sankey flow)
- `Tab` - Cycle camera modes (Siege: follow action vs overview)

---

## Technical Architecture

### Directory Structure

```plaintext
playgrounds/goap/
├── README.md                          # This file
├── common/
│   ├── playground_base.gd             # Base scene with common controls
│   ├── debug_overlay.gd               # Reusable debug UI component
│   └── visual_helpers.gd              # Drawing utilities (shapes, labels)
├── 01_village_economy/
│   ├── village_economy.tscn           # Main scene
│   ├── village_economy.gd             # Scene controller
│   ├── villager_agent.gd              # Villager GOAPAgent subclass
│   ├── goals/*.tres                   # Goal resources
│   ├── actions/*.tres                 # Action resources
│   └── README.md                      # Scenario details
├── 02_ecosystem/
│   ├── ecosystem.tscn
│   ├── creature_agent.gd              # Base creature
│   ├── herbivore.gd / predator.gd / scavenger.gd
│   └── ...
├── 03_crafting_factory/
│   ├── crafting_factory.tscn
│   ├── crafter_agent.gd
│   └── ...
└── 04_siege_warfare/
	├── siege_warfare.tscn
	├── unit_agent.gd
	├── infantry.gd / archer.gd / siege_operator.gd / commander.gd
	└── ...
```

### Design Principles

#### **1. Resource-Based Configuration**

- Goals and actions defined as `.tres` resources
- Inspectable and modifiable in Godot editor
- Shareable across agent instances

#### **2. Minimal Visuals**

- Colored shapes via `_draw()` calls
- Debug text labels for state/plans
- No sprite assets required
- Fast prototyping, good performance

#### **3. Toggleable Debug UI**

- Clean sandbox by default
- Press F1 for detailed debug panels
- Integrates with GOAPDebugManager
- Shows plans, blackboard state, metrics

#### **4. Shared Blackboard Patterns**

- Global state (stockpiles, formations) in shared blackboard
- Agents read/write during planning/execution
- Mimics real-game integration patterns

#### **5. Parameter Exposure**

- Scene parameters via `@export` variables
- Adjustable in editor for experimentation
- Runtime controls where beneficial

---

## Implementation Patterns

### Agent Setup Pattern

```gdscript
extends GOAPAgent
class_name VillagerAgent

func _ready() -> void:
	# Load goal/action resources
	goals = [
		load("res://playgrounds/goap/01_village_economy/goals/survive_hunger_goal.tres"),
		load("res://playgrounds/goap/01_village_economy/goals/survive_thirst_goal.tres"),
		# ...
	]

	actions = [
		load("res://playgrounds/goap/01_village_economy/actions/gather_food_action.tres"),
		# ...
	]

	# Initialize blackboard
	blackboard.set_value(&"hunger", 0)
	blackboard.set_value(&"thirst", 0)
	blackboard.set_value(&"at_location", &"village")
```

### Scene Controller Pattern

```gdscript
extends Node2D

@export var agent_count: int = 8
@export var resource_spawn_rate: float = 1.0

var _debug_overlay: DebugOverlay
var _agents: Array[GOAPAgent] = []

func _ready() -> void:
	_setup_debug_overlay()
	_spawn_agents(agent_count)
	_spawn_resources()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug"):  # F1
		_debug_overlay.visible = !_debug_overlay.visible

func _process(delta: float) -> void:
	_update_needs(delta)      # Decay hunger/thirst
	_update_visuals()         # Draw agents, resources, plans
```

### Custom Goal Pattern

```gdscript
extends GOAPGoal
class_name SurviveHungerGoal

func _init() -> void:
	goal_name = &"SurviveHunger"
	priority = 10.0
	desired_state = {&"hunger": 0}

func get_priority(state: Dictionary[StringName, Variant]) -> float:
	var hunger = state.get(&"hunger", 0)
	return priority * (hunger / 100.0)  # Higher when hungry

func is_relevant(state: Dictionary[StringName, Variant]) -> bool:
	return state.get(&"hunger", 0) > 30  # Only pursue when hungry enough
```

### Custom Action Pattern

```gdscript
extends GOAPAction
class_name GatherFoodAction

var _progress: float = 0.0

func _init() -> void:
	action_name = &"GatherFood"
	cost = 2.0
	preconditions = {&"at_location": &"field"}
	effects = {&"has_food": true}

func can_execute(state: Dictionary[StringName, Variant]) -> bool:
	return state.get(&"at_location") == &"field"

func enter(agent: GOAPAgent) -> void:
	_progress = 0.0
	# Could trigger gathering animation here

func execute(agent: GOAPAgent, delta: float) -> ExecResult:
	_progress += delta
	if _progress >= 3.0:  # 3 second gathering time
		agent.blackboard.set_value(&"has_food", true)
		return ExecResult.SUCCESS
	return ExecResult.RUNNING

func exit(agent: GOAPAgent) -> void:
	_progress = 0.0
	# Cleanup/stop animation
```

---

## Performance Targets

| Scenario         | Agent Count | Target FPS | Notes                     |
| ---------------- | ----------- | ---------- | ------------------------- |
| Village Economy  | 15 agents   | 60 FPS     | Basic multi-agent         |
| Ecosystem        | 30 agents   | 60 FPS     | Simple goals per creature |
| Crafting Factory | 12 agents   | 60 FPS     | Deep plans but few agents |
| Siege Warfare    | 100 agents  | 30-60 FPS  | Requires frame budgeting  |

---

## Coverage vs Test Suite

**What Playgrounds Add:**

| Feature                     | Test Coverage   | Playground Coverage   |
| --------------------------- | --------------- | --------------------- |
| Basic planning/execution    | ✓ Comprehensive | Realistic scenarios   |
| Multi-agent coordination    | Basic fixtures  | True resource sharing |
| Deep action chains (5-7+)   | Limited         | Crafting factory      |
| Large scale (50-100 agents) | None            | Siege warfare         |
| Emergent behaviors          | None            | Ecosystem, village    |
| Performance stress          | Benchmarks only | Interactive profiling |
| Real-world patterns         | Minimal         | All 4 scenarios       |

Playgrounds complement tests by demonstrating **practical usage** rather than validating **correctness**.

---

## Development Roadmap

### Phase 1: Common Infrastructure

- [ ] Directory structure
- [ ] `playground_base.gd` with input handling
- [ ] `debug_overlay.gd` with toggleable UI
- [ ] `visual_helpers.gd` drawing utilities

### Phase 2: Village Economy

- [ ] Scene structure and villager agent
- [ ] 4 goal resources (hunger, thirst, contribute, rest)
- [ ] 7 action resources (gather, eat, drink, deposit, move)
- [ ] Resource nodes and stockpile system
- [ ] Visual feedback and parameter controls
- [ ] Scenario README

### Phase 3: Ecosystem Simulation

- [ ] Creature agent base class
- [ ] 3 creature types (herbivore, predator, scavenger)
- [ ] Goals/actions per creature type
- [ ] Grass patch system with regeneration
- [ ] Death/corpse/reproduction mechanics
- [ ] Population tracking graph
- [ ] Scenario README

### Phase 4: Crafting Factory

- [ ] Crafter agent and station system
- [ ] Crafting goals with dynamic priorities
- [ ] Multi-tier crafting actions (5 tiers)
- [ ] Storage and logistics system
- [ ] Customer order queue
- [ ] Sankey diagram visualization
- [ ] Scenario README

### Phase 5: Siege Warfare

- [ ] Unit agent base and 4 subtypes
- [ ] Military goals (attack, defend, formation)
- [ ] Combat actions per unit type
- [ ] Formation management system
- [ ] Wall/siege mechanics
- [ ] Performance monitoring dashboard
- [ ] Stress testing and optimization
- [ ] Scenario README

### Phase 6: Documentation

- [x] Main README (this file)
- [ ] Scenario-specific READMEs
- [ ] Troubleshooting guide
- [ ] Pattern library

---

## References

**Core GOAP Documentation:**

- `/systems/goap/design_document.md` - System architecture and patterns
- `/systems/goap/core/` - Core GOAP implementation files

**Test Fixtures:**

- `/tests/goap/fixtures/` - Fixture patterns for agent setup
- `/tests/goap/` - Test suite for validation

**Debug System:**

- `/systems/goap/debug/` - Debug UI and event logging

---

## Contributing

When adding new playgrounds:

1. **Follow naming conventions:** `##_descriptive_name/`
2. **Use common infrastructure:** Extend `playground_base.gd`
3. **Document thoroughly:** Include scenario README
4. **Keep visuals minimal:** Colored shapes + debug text
5. **Expose parameters:** Use `@export` for experimentation
6. **Add to progression:** Update learning path in this README

---

## License

Same as parent GOAP system.

---

**Last Updated:** 2026-01-27
**GOAP Version:** Compatible with current main branch
