# Village Resource Economy

**Genre:** Survival/Simulation | **Complexity:** Simple | **Agents:** 5-15

## Overview

The Village Economy playground demonstrates multi-agent resource management through GOAP.
Villagers balance personal survival needs (hunger, thirst, stamina)
with contributing to community stockpiles.
Emergent cooperation patterns arise naturally from individual goal-driven decisions.

## What It Demonstrates

- **Multi-agent coordination** via shared blackboard state
- **Dynamic goal prioritization** based on changing needs
- **Emergent cooperation** without explicit teamwork code
- **Resource management** patterns through gathering and consumption

## Scenario

Villagers live in a small settlement with access to:

- **Field** - Gather food
- **Well** - Fetch water
- **Forest** - Gather wood
- **Village** - Rest and recover stamina
- **Stockpile** - Deposit resources for the community

Each villager has three primary needs:

1. **Hunger** (0-100) - Increases at 5/sec, critical above 70
2. **Thirst** (0-100) - Increases at 7/sec, critical above 70
3. **Stamina** (0-100) - Consumed by gathering, restored by resting

Villagers autonomously decide when to gather resources for themselves vs. contribute to the stockpile based on their current needs.

## GOAP Configuration

### Goals

| Goal              | Priority                            | Relevance           | Achievement      |
| ----------------- | ----------------------------------- | ------------------- | ---------------- |
| **SurviveHunger** | 0-10 (scales with hunger)           | hunger > 30         | hunger < 20      |
| **SurviveThirst** | 0-10 (scales with thirst)           | thirst > 30         | thirst < 20      |
| **Rest**          | 0-5 (scales inversely with stamina) | stamina < 40        | stamina > 80     |
| **Contribute**    | 3.0 (constant)                      | All needs satisfied | After depositing |

### Actions

| Action               | Cost | Preconditions                        | Effects                     | Duration |
| -------------------- | ---- | ------------------------------------ | --------------------------- | -------- |
| **MoveTo[Location]** | 1.0  | -                                    | at_location: [location]     | 2.0s     |
| **GatherFood**       | 2.0  | at_location: field                   | has_food: true              | 3.0s     |
| **FetchWater**       | 2.0  | at_location: well                    | has_water: true             | 2.5s     |
| **GatherWood**       | 2.5  | at_location: forest                  | has_wood: true              | 3.5s     |
| **EatFood**          | 1.0  | has_food: true                       | hunger: 0, has_food: false  | 1.5s     |
| **DrinkWater**       | 1.0  | has_water: true                      | thirst: 0, has_water: false | 1.0s     |
| **Rest**             | 1.0  | at_location: village                 | stamina: 100                | 4.0s     |
| **DepositResources** | 1.5  | at_location: stockpile, has_resource | contributed: true           | 1.5s     |

## Controls

- **F1** - Toggle debug overlay
- **Space** - Pause/Resume simulation
- **R** - Reset scenario
- **1/2/5/X** - Time scale (1x, 2x, 5x, 10x)
- **Mouse Click** - Select villager to inspect

## Learning Objectives

### 1. Multi-Agent Resource Sharing

Watch how villagers coordinate resource gathering without explicit communication. The shared blackboard (stockpile) provides implicit coordination.

### 2. Dynamic Priority Changes

Observe how goal priorities shift based on needs:

- Low hunger → Contribute to stockpile
- High hunger → Drop everything and eat
- Critical thirst → Highest priority override

### 3. Emergent Cooperation

No villager has a "cooperate" behavior, yet cooperation emerges:

- Some villagers gather while others contribute
- Resource scarcity causes prioritization shifts
- Community stockpile grows when needs are met

### 4. Action Chain Planning

See GOAP planning in action:

- Hungry → Need food → Must go to field → Gather → Return → Eat
- Typical plan: `[MoveToField, GatherFood, EatFood]`

## Experimentation

### Scenario Parameters

Adjustable via Godot Inspector or code:

```gdscript
@export var villager_count: int = 8  # 3-15 villagers
@export var resource_spawn_rate: float = 1.0  # Resource abundance
@export var need_decay_rate: float = 1.0  # How fast needs increase
```

### Interesting Experiments

#### **1. Resource Scarcity**

- Set `need_decay_rate = 2.0` (fast hunger/thirst)
- Watch villagers prioritize survival over contribution
- Observe emergent competition for resources

#### **2. Population Pressure**

- Set `villager_count = 15`
- See how the system handles high agent count
- Notice performance characteristics

#### **3. Abundant Resources**

- Set `need_decay_rate = 0.5` (slow needs)
- Watch more contribution behavior emerge
- Stockpile grows faster

## Debug Overlay

Press **F1** to see:

### Selected Agent Panel

- Current state (IDLE/PLANNING/PERFORMING)
- Active goal and priority
- Current action
- Full blackboard state (needs, inventory, location)

### Performance Metrics

- FPS and time scale
- Villager counts by state
- Resource node counts
- Stockpile levels

## Expected Behavior

### Typical Villager Cycle

1. **Spawn** - Start at village with full stamina, no needs
2. **Idle Period** - Needs below threshold, may contribute
3. **First Need** - Hunger/thirst rises, triggers gathering
4. **Action Plan** - Move → Gather → Consume
5. **Stamina Depletion** - After several gathers, return to rest
6. **Repeat** - Continuous cycle of needs and goals

### Population Dynamics

**Low Population (3-5 villagers):**

- More individual agency
- Clear tracking of each villager's plan
- Stockpile grows slowly

**Medium Population (8-10 villagers):**

- Balanced resource usage
- Some specialization emerges
- Good for observing cooperation

**High Population (12-15 villagers):**

- Resource contention
- Faster stockpile growth
- Performance testing

## Implementation Notes

### File Structure

```plaintext
01_village_economy/
├── README.md                      # This file
├── village_economy.tscn           # Main scene
├── village_economy.gd             # Scene controller
├── villager_agent.gd              # Agent subclass
├── goals/
│   ├── survive_hunger_goal.gd
│   ├── survive_thirst_goal.gd
│   ├── rest_goal.gd
│   └── contribute_goal.gd
└── actions/
    ├── move_to_action.gd
    ├── gather_food_action.gd
    ├── fetch_water_action.gd
    ├── gather_wood_action.gd
    ├── eat_food_action.gd
    ├── drink_water_action.gd
    ├── rest_action.gd
    └── deposit_resources_action.gd
```

### Key Patterns Used

#### **1. Shared Blackboard for Coordination**

```gdscript
var _shared_blackboard: GOAPState = GOAPState.new()
_shared_blackboard.set_value(&"stockpile_food", 0)
```

#### **2. Dynamic Goal Priority**

```gdscript
func get_priority(state: Dictionary[StringName, Variant]) -> float:
    var hunger_value := state.get(&"hunger", 0.0) as float
    return priority * (hunger_value / 100.0)  # Scales 0-10
```

#### **3. Parameterized Actions**

```gdscript
var move_to_field := MoveToAction.new(&"field")
var move_to_well := MoveToAction.new(&"well")
```

#### **4. State-Based Action Execution**

```gdscript
func execute(agent: GOAPAgent, delta: float) -> ExecResult:
    _timer += delta
    if _timer >= _duration:
        agent.blackboard.set_value(&"has_food", true)
        return ExecResult.SUCCESS
    return ExecResult.RUNNING
```

## Performance Targets

- **8 villagers** - 60 FPS stable
- **15 villagers** - 50+ FPS
- **Planning time** - < 1ms per villager per plan

## Next Steps

After understanding this scenario, move to:

1. **Ecosystem Simulation** - More complex behaviors, reactive goals
2. **Crafting Factory** - Deep action chains, dependencies
3. **Siege Warfare** - Large-scale orchestration, performance optimization

## Troubleshooting

**Villagers not moving:**

- Check that `MoveToAction` is updating actor position
- Verify location centers are set correctly

**Plans not forming:**

- Use debug overlay (F1) to inspect agent state
- Check goal relevance conditions
- Verify action preconditions/effects match goal desired states

**Poor performance:**

- Reduce villager count
- Check for infinite planning loops
- Profile with Godot's performance monitor
