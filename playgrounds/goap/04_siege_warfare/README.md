# Siege Warfare

**Genre:** Strategy/Tactics | **Complexity:** Advanced | **Agents:** 50-100

## Overview

The Siege Warfare playground demonstrates large-scale GOAP orchestration under performance constraints.
Two armies (attackers and defenders) with multiple unit types engage in tactical combat.
Units maintain formations, coordinate attacks, and adapt to battlefield conditions - all through individual goal-driven AI.

## What It Demonstrates

- **Large-scale orchestration** (50-100 simultaneous agents)
- **Frame-budgeted scheduling** (performance management under load)
- **Formation maintenance** via shared state
- **Commander-unit hierarchy** patterns
- **Performance monitoring** and optimization techniques
- **Emergent tactics** (flanking, retreats, coordination)

## Scenario

Two armies clash on a battlefield with a defensive wall:

### Attacker Army (33 units default)

- **20 Infantry** - Melee fighters, shield wall formation
- **10 Archers** - Ranged support, fall back when pressured
- **2 Siege Operators** - Operate catapults, breach walls
- **1 Commander** - Assigns formations, leads charge

### Defender Army (24 units default)

- **15 Infantry** - Hold the line, defend wall
- **8 Archers** - Rain arrows from safety
- **1 Commander** - Coordinate defense, tactical retreats

**Total:** 57 agents by default (scalable to 100+)

## GOAP Configuration

### Infantry Goals

| Goal                  | Priority | Trigger                  |
| --------------------- | -------- | ------------------------ |
| **MaintainFormation** | 12.0     | Has formation assignment |
| **EngageCombat**      | 15.0     | Enemy in range           |
| **Advance**           | 8.0      | Default behavior         |

**Actions:** MoveToFormation, AttackEnemy, AdvanceForward, DefendPosition

### Archer Goals

| Goal                 | Priority | Trigger                    |
| -------------------- | -------- | -------------------------- |
| **FallBack**         | 20.0     | Enemies within 30 units    |
| **RangedAttack**     | 14.0     | Target in range (80 units) |
| **MaintainDistance** | 10.0     | Positioning                |

**Actions:** FallBack, RangedAttackAction, Reposition

### Siege Operator Goals

| Goal                | Priority | Trigger                |
| ------------------- | -------- | ---------------------- |
| **OperateSiege**    | 18.0     | Equipment available    |
| **DefendEquipment** | 16.0     | Equipment under attack |

**Actions:** OperateCatapult, DefendSiege, RepairEquipment

### Commander Goals

| Goal                | Priority | Trigger        |
| ------------------- | -------- | -------------- |
| **CommandTroops**   | 20.0     | Always         |
| **LeadCharge**      | 15.0     | Battle engaged |
| **TacticalRetreat** | 25.0     | Health < 30%   |

**Actions:** AssignFormation, IssueAdvance, IssueRetreat, LeadByExample

## Controls

- **F1** - Toggle debug overlay
- **Space** - Pause/Resume battle
- **R** - Reset scenario
- **Tab** - Toggle performance dashboard
- **1/2/5/X** - Time scale (1x, 2x, 5x, 10x)
- **Mouse Click** - Select unit to inspect

## Learning Objectives

### 1. Large-Scale GOAP Performance

Watch 50-100 agents plan and execute simultaneously:

- **Planning distribution** - Not all agents plan every frame
- **Action execution overhead** - Bulk of frame time
- **State synchronization** - Shared battlefield awareness
- **Performance bottlenecks** - Where optimization matters

### 2. Formation-Based AI

Observe tactical coordination without explicit teamwork:

- **Commander assignment** - Units receive formation positions
- **Formation maintenance** - Units move to assigned spots
- **Formation breaking** - Combat overrides positioning
- **Emergent tactics** - Shield walls, archer lines form naturally

### 3. Reactive Priorities in Combat

See priority system handle battlefield chaos:

- **Archer retreat** (priority 20) overrides **attack** (priority 14)
- **Commander retreat** (priority 25) overrides **command** (priority 20)
- **Formation** vs **Combat** - context-dependent priorities
- Real-time adaptation to changing threats

### 4. Performance Under Load

Experience GOAP at scale:

- **57 agents** - Default scenario, smooth 60 FPS
- **100 agents** - Stress test, may drop to 30-45 FPS
- **Frame budgeting** - Can limit planning time per frame
- **Optimization points** - Identifies bottlenecks

## Experimentation

### Scenario Parameters

```gdscript
@export var attacker_infantry: int = 20
@export var attacker_archers: int = 10
@export var attacker_siege: int = 2
@export var attacker_commanders: int = 1

@export var defender_infantry: int = 15
@export var defender_archers: int = 8
@export var defender_commanders: int = 1

@export var frame_budget_ms: float = 5.0  # Performance limit
```

### Interesting Experiments

#### **1. Mass Battle**

- Set all counts to 25 (100 total units)
- Watch performance dashboard (Tab)
- Observe FPS drop and frame time increase
- See where bottlenecks appear

#### **2. Imbalanced Forces**

- Attackers: 40 units
- Defenders: 10 units
- Watch overwhelming force in action
- Defenders use tactical retreats

#### **3. No Commanders**

- Set commanders to 0
- Units lack formation assignments
- More chaotic, less coordinated
- Still effective through individual decisions

#### **4. Archer-Only Battle**

- Set infantry/siege to 0, archers to 30 each side
- Watch constant repositioning
- Fallback behavior creates dynamic movement
- Kiting tactics emerge

## Performance Dashboard (Press Tab)

Real-time metrics showing:

- **FPS** - Current frames per second
- **Frame Time** - Milliseconds per frame (vs budget)
- **Active Units** - Living agents count
- **Army Counts** - Attackers vs Defenders remaining

**Color Coding:**

- Green frame time = Under budget (good performance)
- Red frame time = Over budget (performance strain)

## Debug Overlay (Press F1)

### Selected Unit Panel

- Unit type and army
- Current health
- Active goal and priority
- Current action
- Formation assignment (if any)
- Combat target (if any)

### Performance Metrics

- Total units alive
- Attacker count
- Defender count
- Frame processing time

## Expected Behavior

### Battle Flow

#### **Phase 1: Initial Engagement (0-30s)**

1. Commanders assign formations
2. Units move to positions
3. Armies advance toward center
4. First contact near wall

#### **Phase 2: Main Combat (30-120s)**

1. Infantry clash in melee
2. Archers provide ranged support
3. Archers fall back when pressured
4. Siege operators attack wall
5. Commanders lead from front

#### **Phase 3: Resolution (120s+)**

1. One army gains advantage
2. Losing side takes casualties
3. Commander may order retreat
4. Victory or mutual decimation

### Tactical Patterns

**Attacker Strategy:**

- Infantry push forward
- Archers support from distance
- Siege breaches wall
- Commander leads final charge

**Defender Strategy:**

- Infantry hold wall line
- Archers exploit range advantage
- Fall back if overwhelmed
- Commander coordinates defense

### Emergent Behaviors

Watch for:

- **Shield walls** - Infantry cluster naturally
- **Archer lines** - Ranged units form ranks
- **Flanking** - Units move around obstacles
- **Retreats** - Damaged commanders pull back
- **Pursuit** - Winners chase fleeing enemies

## Performance Targets

| Unit Count | Target FPS | Notes           |
| ---------- | ---------- | --------------- |
| 50 units   | 60 FPS     | Comfortable     |
| 75 units   | 45-60 FPS  | Noticeable load |
| 100 units  | 30-45 FPS  | Stress test     |

**Optimization Opportunities:**

- Spatial partitioning for enemy detection
- LOD-based update frequencies
- Action execution pooling
- Formation caching

## Implementation Notes

### Key Design Patterns

#### **1. Commander-Unit Relationship**

```gdscript
# Commander assigns formations
func execute(agent: GOAPAgent, delta: float) -> ExecResult:
    var commander := agent as Commander
    var units := commander.get_commanded_units()
    for i in range(units.size()):
        var offset := Vector2(i * 20.0, 0)
        units[i].assign_formation(commander.position + offset, commander)
```

#### **2. Reactive Priority System**

```gdscript
# Archer fallback overrides attack
class FallBackGoal:
    priority = 20.0  # Higher than RangedAttackGoal (14.0)

func get_priority(state) -> float:
    return priority if enemies_in_melee_range > 0 else 0.0
```

#### **3. Efficient Enemy Detection**

```gdscript
func detect_enemies_in_range(range_distance: float) -> Array[UnitAgent]:
    # Spatial query (could be optimized with quadtree/grid)
    var detected: Array[UnitAgent] = []
    for unit in all_units:
        if unit.army != self.army and distance < range_distance:
            detected.append(unit)
    return detected
```

#### **4. Formation Maintenance**

```gdscript
# Units constantly move toward assigned position
func execute(agent: GOAPAgent, delta: float) -> ExecResult:
    var distance := unit.move_toward(unit.formation_position, delta)
    if distance < 5.0:
        unit.enter_formation()
        return ExecResult.SUCCESS
    return ExecResult.RUNNING
```

### File Structure

```plaintext
04_siege_warfare/
├── README.md
├── siege_warfare.tscn / .gd
├── unit_agent.gd (base)
├── infantry.gd / archer.gd / siege_operator.gd / commander.gd
├── goals/ (11 goal classes)
└── actions/ (15 action classes)
```

## Troubleshooting

**Poor performance:**

- Reduce unit counts
- Lower time scale to 1x
- Check performance dashboard
- Profile enemy detection (most expensive)

**Units not engaging:**

- Check detection range (100 units)
- Verify army assignments (attacker vs defender)
- Inspect target_enemy in debug overlay

**Formations not working:**

- Verify commander is alive
- Check formation assignments
- Ensure MaintainFormation goal is active

**Instant deaths:**

- Adjust attack_damage values
- Increase max_health
- Balance army compositions

## Next Steps

**Congratulations!** You've completed all 5 GOAP playgrounds!

You've learned:

1. **Village Economy** - Multi-agent basics
2. **Ecosystem** - Reactive behaviors, emergent patterns
3. **Crafting Factory** - Deep planning, dependencies
4. **Siege Warfare** - Large-scale performance, tactics

**Further Exploration:**

- Implement custom scenarios
- Optimize performance bottlenecks
- Add new unit types
- Create custom formation patterns
- Integrate with your game project!

---

**Status:** ✅ Phase 5 Complete - ALL PLAYGROUNDS FINISHED!
**Created:** 2026-01-27
**GOAP Version:** Compatible with main branch
