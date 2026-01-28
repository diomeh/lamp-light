# Crafting Chain Factory

**Genre:** Automation/Crafting | **Complexity:** Medium-Advanced | **Agents:** 3-12

## Overview

The Crafting Factory playground demonstrates deep action chain planning through GOAP.
Crafters autonomously produce complex items via multi-tier crafting chains (ore → ingots → tools → gears → machines).
Just-in-time production emerges naturally from order priorities,
creating an efficient supply chain without explicit orchestration.

## What It Demonstrates

- **Deep action chains** (5-7 step plans from raw materials to final product)
- **Multi-stage dependency planning** (products require other products as ingredients)
- **Just-in-time production** (crafters make what's needed when it's needed)
- **Resource reservation** (station occupancy prevents conflicts)
- **Bottleneck detection** (single assembly station creates natural chokepoint)

## Scenario

6 crafters operate a factory with 6 station types producing 5-tier crafting chains:

### Crafting Tiers

```plaintext
Tier 1 (Raw): Mine 2 ore → Gather 1 wood
                ↓             ↓
Tier 2:      1 ore → 1 iron_ingot
                        ↓
Tier 3:      2 ingot + 1 wood → 1 tool
                        ↓
Tier 4:      5 ingot + 1 tool → 1 gear
                        ↓
Tier 5:      3 gear + 2 tool → 1 machine
```

### Stations

| Station      | Type   | Count | Purpose                        | Time |
| ------------ | ------ | ----- | ------------------------------ | ---- |
| **Mine**     | Raw    | 2     | Extract ore                    | 2s   |
| **Forest**   | Raw    | 2     | Gather wood                    | 2s   |
| **Furnace**  | Tier 2 | 2     | Smelt ore → ingot              | 3s   |
| **Workshop** | Tier 3 | 2     | Craft ingot + wood → tool      | 5s   |
| **Factory**  | Tier 4 | 2     | Craft ingot + tool → gear      | 8s   |
| **Assembly** | Tier 5 | 1     | Assemble gear + tool → machine | 12s  |

**Note:** Assembly has only 1 station (intentional bottleneck!)

## GOAP Configuration

### Goals

Goals are dynamically prioritized by tier and order quantity:

| Goal                         | Base Priority     | Scaling                   |
| ---------------------------- | ----------------- | ------------------------- |
| **FulfillOrder[machine]**    | 25.0 (tier 5 × 5) | × order quantity (max 3x) |
| **FulfillOrder[gear]**       | 20.0 (tier 4 × 5) | × order quantity          |
| **FulfillOrder[tool]**       | 15.0 (tier 3 × 5) | × order quantity          |
| **FulfillOrder[iron_ingot]** | 10.0 (tier 2 × 5) | × order quantity          |
| **Idle**                     | 1.0               | Fallback                  |

### Actions (11 total)

**Raw Material Gathering:**

- `MineOre` (cost 2.0) - Get 1 ore
- `GatherWood` (cost 2.0) - Get 1 wood

**Crafting (5 tiers):**

- `SmeltIngot` (cost 3.0) - 1 ore → 1 ingot (3s)
- `CraftTool` (cost 4.0) - 2 ingot + 1 wood → 1 tool (5s)
- `CraftGear` (cost 5.0) - 5 ingot + 1 tool → 1 gear (8s)
- `AssembleMachine` (cost 6.0) - 3 gear + 2 tool → 1 machine (12s)

**Logistics:**

- `DepositProduct` (cost 2.0) - Put finished goods in storage
- `RetrieveMaterial` (cost 2.0) - Get materials from storage
- `MoveToStation` (cost 1.0) - Navigate to station
- `Idle` (cost 0.5) - Wait when no work

## Example Deep Plan

**Order:** 1 machine

**Crafter's Plan (7 steps):**

```plaintext
1. MineOre (at mine) → Get ore
2. SmeltIngot (at furnace) → ore → ingot
3. GatherWood (at forest) → Get wood
4. CraftTool (at workshop) → 2 ingot + wood → tool
5. CraftGear (at factory) → 5 ingot + tool → gear
6. AssembleMachine (at assembly) → 3 gear + 2 tool → machine
7. DepositProduct (at storage) → Complete order
```

**Dependencies:**

- Step 4 requires Step 2 (need ingots) AND Step 3 (need wood)
- Step 5 requires Step 4 (need tool) AND more Step 2 (need more ingots)
- Step 6 requires multiple Step 5 (need 3 gears) AND more Step 4 (need 2 tools)

This creates a **dependency tree** that GOAP solves automatically!

## Controls

- **F1** - Toggle debug overlay
- **Space** - Pause/Resume simulation
- **R** - Reset scenario
- **D** - Toggle Sankey production diagram
- **1/2/5/X** - Time scale (1x, 2x, 5x, 10x)
- **Mouse Click** - Select crafter to inspect

## Learning Objectives

### 1. Deep Action Chain Planning

Watch GOAP plan 5-7 step sequences:

- Planner works **backwards** from goal (machine)
- Identifies all prerequisite materials
- Finds action sequence to obtain them
- Handles nested dependencies automatically

### 2. Just-In-Time Production

No central controller, yet efficient production emerges:

- **Demand-driven** - Only make what's ordered
- **Distributed** - Each crafter plans independently
- **Efficient** - Minimal waste, no overproduction
- **Adaptive** - Changes with order priorities

### 3. Resource Reservation

Station system prevents conflicts:

- Crafter reserves station before traveling
- Other crafters see station as occupied
- Plan around unavailable stations
- Release on completion or failure

### 4. Bottleneck Detection

Assembly station (1 unit) creates natural bottleneck:

- Watch crafters queue for assembly
- Downstream products pile up waiting
- Upstream materials process faster
- Realistic factory simulation!

## Experimentation

### Scenario Parameters

```gdscript
@export var crafter_count: int = 6               # Number of workers
@export var auto_generate_orders: bool = true    # Continuous orders
@export var order_interval: float = 10.0         # Seconds between orders
```

### Interesting Experiments

#### **1. Increase Workers**

- Set `crafter_count = 12`
- Watch bottleneck at assembly station
- Multiple crafters wait for single assembly slot
- Demonstrates station contention

#### **2. Remove Bottleneck**

- Modify `_setup_stations()` to add 2nd assembly station
- Production smooths out significantly
- Higher throughput for machines
- Less idle time

#### **3. Complex Order**

- Generate order for 5 machines simultaneously
- Watch massive dependency resolution
- Crafters coordinate without communication
- Supply chain emerges organically

#### **4. Material Scarcity**

- Manually set low initial ore/wood
- Crafters compete for raw materials
- Higher-priority orders get resources first
- Lower tiers starve temporarily

## Sankey Diagram (Press D)

Visual production flow tracker showing:

- **Iron Ingot** production (Tier 2)
- **Tool** production (Tier 3)
- **Gear** production (Tier 4)
- **Machine** production (Tier 5)

Bar widths represent cumulative production counts.

## Debug Overlay (Press F1)

### Selected Crafter Panel

- Current state and goal
- Active action
- Inventory contents (ore, ingots, tools, gears, machines)
- Full plan visualization

### Performance Metrics

- Crafter count
- Active orders
- Storage levels (all materials)
- Station occupancy (e.g., "3/11 occupied")

## Expected Behavior

### Typical Crafter Workflow

**For Machine Order:**

1. **Planning Phase** (IDLE → PLANNING)
   - Goal selected: FulfillOrder[machine]
   - Plan created: [MineOre, SmeltIngot, ..., AssembleMachine, Deposit]

2. **Execution Phase** (PLANNING → PERFORMING)
   - Execute actions sequentially
   - Reserve stations as needed
   - Build up intermediate materials in inventory

3. **Completion** (PERFORMING → IDLE)
   - Deposit finished machine
   - Order fulfilled
   - Return to idle, await new order

### Production Flow

**Steady State (1 machine order):**

1. Multiple crafters mine ore / gather wood
2. Smelting happens at furnace stations
3. Tool crafting at workshop (needs ingots + wood)
4. Gear crafting at factory (needs ingots + tool)
5. Machine assembly at bottleneck (needs gears + tools)
6. Deposit to storage

**Parallelization:**

- Raw gathering: highly parallel (4 stations)
- Mid-tier crafting: parallel (2-4 stations per tier)
- Final assembly: serialized (1 station = bottleneck)

## Performance Targets

- **6 crafters** - 60 FPS stable
- **12 crafters** - 60 FPS (with bottleneck waiting)
- **Planning time** - 1-5ms for complex 7-step plans

## Implementation Notes

### Key Design Patterns

#### **1. Tiered Goal System**

```gdscript
func _init(target_product: StringName, production_tier: int) -> void:
    priority = float(tier) * 5.0  # Higher tier = higher priority
```

#### **2. Station Reservation**

```gdscript
func enter(agent: GOAPAgent) -> void:
    _target_station = factory.find_available_station(&"furnace")
    if _target_station:
        _target_station.reserve(crafter)
```

#### **3. Inventory Management**

```gdscript
func add_material(material: StringName, amount: int) -> bool:
    if total + amount > MAX_INVENTORY:
        return false
    inventory[material] += amount
    return true
```

#### **4. Multi-Stage Preconditions**

```gdscript
# CraftGear requires 5 ingots + 1 tool
preconditions = {&"iron_ingot": 5, &"tool": 1}
effects = {&"gear": 1}
```

### File Structure

```plaintext
03_crafting_factory/
├── README.md
├── crafting_factory.tscn / .gd
├── crafter_agent.gd
├── crafting_station.gd
├── goals/
│   ├── fulfill_order_goal.gd
│   └── idle_goal.gd
└── actions/
    ├── mine_ore_action.gd
    ├── gather_wood_action.gd
    ├── smelt_ingot_action.gd
    ├── craft_tool_action.gd
    ├── craft_gear_action.gd
    ├── assemble_machine_action.gd
    ├── deposit_product_action.gd
    ├── retrieve_material_action.gd
    ├── move_to_station_action.gd
    └── idle_action.gd
```

## Troubleshooting

**Crafters idle with active orders:**

- Check if stations are reserved but not released
- Verify action exit() releases stations
- Inspect blackboard for stale state

**Plans fail repeatedly:**

- Check material availability in storage
- Verify station availability
- Use debug overlay to see failure reason

**Bottleneck too severe:**

- Add 2nd assembly station in `_setup_stations()`
- Or reduce machine order frequency
- Or increase crafter count

**Inventory overflow:**

- Crafters have MAX_INVENTORY = 10
- Large recipes may not fit
- Adjust inventory limits if needed

## Next Steps

After understanding this scenario, move to:

1. **Siege Warfare** - 100-agent stress test with formation AI

---

**Status:** ✅ Phase 4 Complete
**Created:** 2026-01-27
**GOAP Version:** Compatible with main branch
