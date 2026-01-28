# Ecosystem Simulation

**Genre:** Simulation | **Complexity:** Simple-Medium | **Agents:** 20-30

## Overview

The Ecosystem playground demonstrates emergent predator-prey dynamics through GOAP.
Herbivores graze and flee predators, predators hunt when hungry, and scavengers clean up corpses.
Population balance emerges naturally from individual goal-driven behaviors.

## What It Demonstrates

- **Predator-prey dynamics** from individual behaviors
- **Environmental interaction** (grass depletion/regrowth)
- **Reactive behaviors** (fleeing = high-priority goal interrupts)
- **Emergent population balance** without explicit population control
- **Multi-species ecosystem** with food chains

## Scenario

30 creatures inhabit a simple ecosystem:

- **15 Herbivores** (green) - Graze grass, flee predators, reproduce when well-fed
- **3 Predators** (red) - Hunt herbivores when hungry, rest when full, patrol territory
- **5 Scavengers** (brown) - Scavenge corpses, socialize in groups

### Environment

- **30 Grass Patches** - Herbivore food source, depletes when grazed, regenerates over time
- **Corpses** - Created when creatures die, provide food for scavengers
- **World Bounds** - 800x600 area

## GOAP Configuration

### Herbivore

| Goal          | Priority                 | Behavior                     |
| ------------- | ------------------------ | ---------------------------- |
| **Flee**      | 0-100 (distance-based)   | Escape from nearby predators |
| **Graze**     | 0-10 (energy-based)      | Eat grass to restore energy  |
| **Reproduce** | 8.0 (when can_reproduce) | Spawn offspring              |

**Actions:** FleeFromPredator, GrazeGrass, Reproduce

### Predator

| Goal       | Priority            | Behavior                  |
| ---------- | ------------------- | ------------------------- |
| **Hunt**   | 0-15 (energy-based) | Chase and kill herbivores |
| **Rest**   | 5.0 (when well-fed) | Conserve energy           |
| **Patrol** | 3.0 (fallback)      | Wander territory          |

**Actions:** HuntHerbivore, Rest, Patrol

### Scavenger

| Goal          | Priority             | Behavior                    |
| ------------- | -------------------- | --------------------------- |
| **Scavenge**  | 0-12 (energy-based)  | Find and eat corpses        |
| **Socialize** | 4.0 (when satisfied) | Group with other scavengers |

**Actions:** FindCorpse, ScavengeCorpse, Socialize, Reproduce

## Controls

- **F1** - Toggle debug overlay
- **Space** - Pause/Resume simulation
- **R** - Reset scenario
- **G** - Toggle population graph
- **1/2/5/X** - Time scale (1x, 2x, 5x, 10x)
- **Mouse Click** - Select creature to inspect

## Learning Objectives

### 1. Emergent Population Dynamics

Watch how populations self-regulate:

- **Too many predators** → Herbivores decline → Predators starve → Balance restores
- **Too few predators** → Herbivores overpopulate → Grass depletes → Herbivores starve
- **Natural equilibrium** emerges without explicit balancing code

### 2. Reactive vs Deliberative Behavior

Observe the priority system in action:

- **Herbivore grazing** (priority 0-10) is interrupted by **flee** (priority 0-100)
- **Predator hunting** stops when **energy > 70**, switches to **rest**
- High-priority goals override ongoing plans immediately

### 3. Environmental Feedback Loops

See how environment affects behavior:

- Grass depletion forces herbivores to move
- Corpses attract scavengers
- Predator activity creates food for scavengers
- Grass regrowth sustains herbivore population

### 4. Food Chain Emergent Patterns

No hardcoded food chain, yet it emerges:

```plaintext
Grass → Herbivores → Predators
          ↓
       Corpses → Scavengers
```

## Experimentation

### Scenario Parameters

```gdscript
@export var herbivore_count: int = 15       # Initial herbivores
@export var predator_count: int = 3         # Initial predators
@export var scavenger_count: int = 5        # Initial scavengers
@export var energy_decay_rate: float = 1.0  # Hunger speed
@export var grass_regrowth_rate: float = 1.0 # Grass regeneration
```

### Interesting Experiments

#### **1. Predator Explosion**

- Set `predator_count = 10`
- Watch rapid herbivore extinction
- Predators starve shortly after
- Observe population collapse

#### **2. Abundant Food**

- Set `grass_regrowth_rate = 3.0` (fast regrowth)
- Herbivores thrive and overpopulate
- More prey supports more predators
- Stable high-population equilibrium

#### **3. Scarce Resources**

- Set `grass_regrowth_rate = 0.3` (slow regrowth)
- Set `energy_decay_rate = 2.0` (fast hunger)
- Resource scarcity creates instability
- Boom-bust population cycles

#### **4. No Predators**

- Set `predator_count = 0`
- Herbivores multiply unchecked
- Grass becomes scarce
- Herbivore starvation creates natural limit

## Population Graph (Press G)

Real-time tracking shows:

- **Green line** - Herbivore population
- **Red line** - Predator population
- **Brown line** - Scavenger population

Watch for:

- **Lag effect** - Predator population follows herbivore peaks
- **Oscillations** - Natural boom-bust cycles
- **Equilibrium** - Stable point where births = deaths

## Debug Overlay (Press F1)

### Selected Creature Panel

- Creature type and state
- Current goal and priority
- Active action
- Energy level
- Age

### Performance Metrics

- Population counts by species
- Total creature count
- Grass patch count
- Active corpses

## Expected Behavior

### Typical Herbivore Life

1. **Spawn** - Start with 60 energy
2. **Graze** - Eat grass until energy = 80
3. **Detect Predator** - Flee goal overrides grazing
4. **Escape** - Run until predator is far
5. **Return to Grazing** - Resume food gathering
6. **Reproduce** - At energy > 75, spawn offspring
7. **Death** - Energy reaches 0 or max lifespan

### Typical Predator Hunt

1. **Idle/Patrol** - Wander when not hungry
2. **Detect Prey** - Spot herbivore within 100 units
3. **Hunt** - Chase at 120 speed (faster than herbivore's 100)
4. **Kill** - Contact within 15 units kills prey
5. **Eat** - Restore 25 energy/sec for 3 seconds
6. **Rest** - Conserve energy when full

### Population Cycles

**Typical Pattern:**

1. Herbivores graze and multiply
2. More prey → Predators hunt successfully
3. Predator population grows
4. Too many predators → Herbivores decline
5. Food scarcity → Predators starve
6. Predator decline → Herbivores recover
7. Cycle repeats

## Performance Targets

- **30 creatures** - 60 FPS stable
- **50 creatures** - 45-60 FPS
- **Planning time** - < 1ms per creature

## Implementation Notes

### Key Design Patterns

#### **1. Reactive Goal System**

```gdscript
# Flee goal has extremely high priority when threatened
func get_priority(state: Dictionary[StringName, Variant]) -> float:
    var threat_distance := state.get(&"threat_distance", 1000.0) as float
    var distance_factor := clampf(1.0 - (threat_distance / 80.0), 0.0, 1.0)
    return 100.0 * distance_factor  # Up to 100 priority!
```

#### **2. Environmental State Management**

```gdscript
# Grass patches with health
var _grass_patches: Dictionary = {}  # Vector2 -> float (0-100)

# Corpses with remaining food
var _corpses: Dictionary = {}  # Vector2 -> float (0-100)
```

#### **3. Creature Detection**

```gdscript
# Each creature scans for relevant targets
func detect_creatures_in_range(range_distance: float, type_filter: CreatureType)
```

#### **4. Death and Cleanup**

```gdscript
func die() -> void:
    is_dead = true
    abort()  # Stop current plan
    # Notify ecosystem to create corpse
```

### File Structure

```plaintext
02_ecosystem/
├── README.md
├── ecosystem.tscn / ecosystem.gd
├── creature_agent.gd             # Base creature class
├── herbivore.gd / predator.gd / scavenger.gd
├── goals/
│   ├── flee_goal.gd
│   ├── graze_goal.gd
│   ├── hunt_goal.gd
│   ├── rest_goal.gd
│   ├── patrol_goal.gd
│   ├── scavenge_goal.gd
│   ├── socialize_goal.gd
│   └── reproduce_goal.gd
└── actions/
    ├── flee_from_predator_action.gd
    ├── graze_grass_action.gd
    ├── hunt_herbivore_action.gd
    ├── rest_action.gd
    ├── patrol_action.gd
    ├── find_corpse_action.gd
    ├── scavenge_corpse_action.gd
    ├── socialize_action.gd
    └── reproduce_action.gd
```

## Troubleshooting

**Extinction events:**

- Adjust initial population ratios
- Increase grass regrowth rate
- Decrease energy decay rate

**No hunting:**

- Check predator detection range (100 units)
- Verify predator energy < 70 for hunt goal relevance
- Use debug overlay to inspect predator state

**Herbivores not fleeing:**

- Flee detection range is 80 units
- Check that threat_detected is being set
- Verify flee goal priority calculation

**Poor performance:**

- Reduce creature counts
- Limit history tracking (MAX_HISTORY_POINTS)
- Profile creature detection frequency

## Next Steps

After understanding this scenario, move to:

1. **Crafting Chain Factory** - Deep action chains, complex dependencies
2. **Siege Warfare** - Large-scale optimization, performance stress testing
