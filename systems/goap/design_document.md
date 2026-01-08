# Goal-Oriented Action Planning (GOAP) Architecture and Design

## Table of Contents

- [Goal-Oriented Action Planning (GOAP) Architecture and Design](#goal-oriented-action-planning-goap-architecture-and-design)
  - [Table of Contents](#table-of-contents)
  - [1. Overview](#1-overview)
    - [1.1 Purpose](#11-purpose)
    - [1.2 Design Goals](#12-design-goals)
  - [2. Architecture](#2-architecture)
    - [2.1 System Overview](#21-system-overview)
    - [2.2 Component Responsibilities](#22-component-responsibilities)
    - [2.3 Design Rationale](#23-design-rationale)
  - [3. Execution Flow](#3-execution-flow)
    - [3.1 Orchestrator Scheduling](#31-orchestrator-scheduling)
    - [3.2 Agent State Machine](#32-agent-state-machine)
    - [3.3 Action Lifecycle](#33-action-lifecycle)
    - [3.4 Planning Algorithm](#34-planning-algorithm)
  - [4. Communication Patterns](#4-communication-patterns)
  - [5. File Structure](#5-file-structure)
  - [6. Configuration](#6-configuration)
    - [6.1 Autoloads](#61-autoloads)
    - [6.2 Orchestrator Tuning](#62-orchestrator-tuning)
  - [7. Common Patterns](#7-common-patterns)
    - [7.1 Dynamic Priority Goal](#71-dynamic-priority-goal)
    - [7.2 Dynamic Cost Action](#72-dynamic-cost-action)
    - [7.3 LOD for Agents](#73-lod-for-agents)
    - [7.4 Sensors](#74-sensors)
  - [8. Debugging](#8-debugging)
    - [8.1 Observable Signals](#81-observable-signals)
    - [8.2 Recommended Debug Overlay](#82-recommended-debug-overlay)
  - [9. Extensibility](#9-extensibility)
    - [9.1 Custom Goals](#91-custom-goals)
    - [9.2 Custom Actions](#92-custom-actions)
    - [9.3 Integration Points](#93-integration-points)
  - [10. Glossary](#10-glossary)
  - [11. References](#11-references)
  - [Appendix A: State Key Conventions](#appendix-a-state-key-conventions)
  - [Appendix B: Action Cost Guidelines](#appendix-b-action-cost-guidelines)

## 1. Overview

### 1.1 Purpose

A Goal-Oriented Action Planning system for Godot 4.5+. GOAP enables AI agents to dynamically plan sequences of actions to achieve goals based on current world state.

### 1.2 Design Goals

| Goal              | Description                                            |
| ----------------- | ------------------------------------------------------ |
| **Modularity**    | Goals and actions as reusable Resources                |
| **Performance**   | Staggered thinking with frame budget control           |
| **Flexibility**   | Support static and dynamic preconditions/effects/costs |
| **Debuggability** | Observable state changes, clear execution flow         |
| **Scalability**   | Handle 100+ agents without frame drops                 |

---

## 2. Architecture

### 2.1 System Overview

```plaintext
┌─────────────────────────────────────────────────────────────────────────────┐
│                              AUTOLOADS                                      │
│                                                                             │
│  ┌─────────────────────────────┐    ┌─────────────────────────────────┐     │
│  │      GOAPPlanner            │    │       GOAPOrchestrator          │     │
│  │      (Singleton)            │    │       (Singleton)               │     │
│  │                             │    │                                 │     │
│  │  Stateless A* planning      │    │  Frame-budgeted scheduling      │     │
│  └─────────────────────────────┘    └──────────────┬──────────────────┘     │
└────────────────────────────────────────────────────┼────────────────────────┘
                                                     │ think()
                                                     ▼
┌────────────────────────────────────────────────────────────────────────────┐
│                            GOAPAgent (Node)                                │
│                                                                            │
│  ┌────────────────────────────┐    ┌────────────────────────────┐          │
│  │     GOAPExecutor           │    │        GOAPState           │          │
│  │     (RefCounted)           │    │        (RefCounted)        │          │
│  └────────────────────────────┘    └────────────────────────────┘          │
└────────────────────────────────────────────────────────────────────────────┘

┌────────────────────────────┐          ┌────────────────────────────────────┐
│     GOAPGoal (Resource)    │          │      GOAPAction (Resource)         │
└────────────────────────────┘          └────────────────────────────────────┘
```

### 2.2 Component Responsibilities

| Component        | Type       | Responsibility                                           |
| ---------------- | ---------- | -------------------------------------------------------- |
| GOAPPlanner      | Autoload   | Stateless A* search, returns action sequence             |
| GOAPOrchestrator | Autoload   | Schedules agent thinking within frame budget             |
| GOAPAgent        | Node       | Owns goals/actions/state, coordinates planning/execution |
| GOAPExecutor     | RefCounted | Manages plan execution, tracks current action            |
| GOAPState        | RefCounted | Blackboard storage with change notifications             |
| GOAPGoal         | Resource   | Defines desired state and priority                       |
| GOAPAction       | Resource   | Defines preconditions, effects, cost, execution logic    |

### 2.3 Design Rationale

**Why Resources for Goals/Actions?**

- Shareable across agent types via .tres files
- Editor-friendly with @export properties
- Serializable for save/load systems

**Why Autoload for Planner?**

- Stateless operation requires no per-agent instance
- Single point for planning optimization

**Why RefCounted for Executor?**

- Per-agent state (current plan, action index)
- No scene tree presence needed

**Why Autoload for Orchestrator?**

- Central coordination prevents frame spikes
- Global view enables fair scheduling

**Why Polling over Signals for Action Execution?**

- Simpler control flow for frame-based games
- Easier interruption handling
- Executor drives lifecycle, signals for observation only

---

## 3. Execution Flow

### 3.1 Orchestrator Scheduling

```plaintext
GOAPOrchestrator._physics_process()
    │
    ├─► While within budget AND agents unchecked:
    │       │
    │       ├─► Round-robin to next agent
    │       │
    │       └─► If agent due AND needs_thinking():
    │               │
    │               └─► agent.think()
    │
    └─► Exit when budget exhausted
```

### 3.2 Agent State Machine

```plaintext
                                              ┌──┐
                                              │  │ plan still running
                                              ▼  │
┌──────┐  think()  ┌──────────┐  plan found  ┌────────────┐
│ IDLE │─────────►│ PLANNING │────────────►│ PERFORMING │
└──────┘           └──────────┘              └────────────┘
    ▲                   │                        │
    │                   │ no plan                │ complete/fail
    └───────────────────┴────────────────────────┘
```

| State      | Driven By    | Why                            |
| ---------- | ------------ | ------------------------------ |
| IDLE       | Orchestrator | Can be staggered across frames |
| PLANNING   | Orchestrator | Expensive, must be budgeted    |
| PERFORMING | Agent        | Needs every-frame updates      |

### 3.3 Action Lifecycle

```plaintext
executor.tick()
    │
    ├─► enter()     — called once when action starts
    │
    ├─► execute()   — called each frame, returns ExecResult
    │       │
    │       ├─► RUNNING → continue next frame
    │       ├─► SUCCESS → exit(), advance to next action
    │       └─► FAILURE → exit(), abort plan
    │
    └─► exit()      — called once when action ends
```

### 3.4 Planning Algorithm

Regressive A* search:

1. Start from goal's desired state
2. Find actions whose effects satisfy unsatisfied conditions
3. Regress through action (remove effects, add preconditions)
4. Repeat until all conditions satisfied by current world state
5. Return actions in execution order

Heuristic: max of minimum costs per unsatisfied condition (admissible).

---

## 4. Communication Patterns

```plaintext
Orchestrator ──think()──► Agent ──plan()──► Planner
                             │
                             └──start/tick──► Executor ──enter/execute/exit──► Action
                                                  │
                                                  └──signals──► Observers
```

| Flow                 | Mechanism                                    |
| -------------------- | -------------------------------------------- |
| Orchestrator → Agent | Method call (`think()`)                      |
| Agent → Planner      | Method call (`plan()`)                       |
| Agent → Executor     | Method call (`start()`, `tick()`, `abort()`) |
| Executor → Agent     | Signals (`plan_completed`, `plan_failed`)    |
| Action → State       | Method call (`set_value()`)                  |

---

## 5. File Structure

```plaintext
res://
├── systems/
│   └── goap/
│       ├── core/
│       │   ├── goap_state.gd
│       │   ├── goap_goal.gd
│       │   ├── goap_action.gd
│       │   ├── goap_executor.gd
│       │   ├── goap_agent.gd
│       │   ├── goap_planner.gd
│       │   └── goap_orchestrator.gd
│       ├── goals/
│       │   └── (reusable goal scripts)...
│       ├── actions/
│       │   └── (reusable action scripts)...
│       └── debug/
│           └── goap_debug.gd
├── playgrounds/
│   └── goap/
│       └── (demo scenes)...
└── tests/
    └── goap/
        ├── unit/
        ├── feature/
        ├── end2end/
        ├── fixtures/
        └── helpers/
```

---

## 6. Configuration

### 6.1 Autoloads

| Name             | Path                                         |
| ---------------- | -------------------------------------------- |
| GOAPPlanner      | res://systems/goap/core/goap_planner.gd      |
| GOAPOrchestrator | res://systems/goap/core/goap_orchestrator.gd |

### 6.2 Orchestrator Tuning

| Agent Count | think_budget_ms | min_think_interval |
| ----------- | --------------- | ------------------ |
| 1-20        | 4.0             | 0.3                |
| 20-50       | 6.0             | 0.5                |
| 50-100      | 8.0             | 0.7                |
| 100+        | 8.0             | 1.0 + LOD          |

---

## 7. Common Patterns

### 7.1 Dynamic Priority Goal

Override `get_priority()` to scale urgency based on agent state (e.g., hunger level increases eat goal priority).

### 7.2 Dynamic Cost Action

Override `get_cost()` for context-dependent costs (e.g., navigation cost based on distance).

### 7.3 LOD for Agents

Override `get_think_priority()` to prioritize nearby agents. Distant agents think less frequently.

### 7.4 Sensors

Sensors are separate from GOAP. They observe the world and write to agent's blackboard. GOAP plans only from blackboard (beliefs), never from world state directly.

---

## 8. Debugging

### 8.1 Observable Signals

| Signal         | Source       | Information            |
| -------------- | ------------ | ---------------------- |
| state_changed  | GOAPState    | Blackboard mutations   |
| goal_selected  | GOAPAgent    | Goal chosen            |
| plan_created   | GOAPAgent    | Plan generated         |
| plan_failed    | GOAPAgent    | Planning failed        |
| plan_completed | GOAPAgent    | Goal achieved          |
| plan_aborted   | GOAPAgent    | Action failed mid-plan |
| action_started | GOAPExecutor | Action began           |
| action_ended   | GOAPExecutor | Action finished        |

### 8.2 Recommended Debug Overlay

- Current goal name
- Current plan (action sequence)
- Current action + progress
- Key blackboard values
- Agent FSM state

---

## 9. Extensibility

### 9.1 Custom Goals

Extend GOAPGoal:

- `is_relevant()` — contextual filtering
- `get_priority()` — dynamic urgency
- `after_plan_complete()` — cooldowns, cleanup

### 9.2 Custom Actions

Extend GOAPAction:

- `enter()`/`exit()` — lifecycle hooks
- `execute()` — frame-based logic
- `get_cost()` — dynamic planning cost

### 9.3 Integration Points

| System     | Integration                     |
| ---------- | ------------------------------- |
| Perception | Sensors → blackboard            |
| Animation  | enter()/exit() hooks            |
| Navigation | Poll NavigationAgent in execute |
| Combat     | Blackboard tracks status        |
| Inventory  | Blackboard reflects contents    |

---

## 10. Glossary

| Term             | Definition                                          |
| ---------------- | --------------------------------------------------- |
| **Goal**         | Desired world state agent wants to achieve          |
| **Action**       | Atomic operation with preconditions and effects     |
| **Plan**         | Ordered sequence of actions to achieve goal         |
| **Precondition** | State required before action can execute            |
| **Effect**       | State changes resulting from action completion      |
| **Regression**   | Working backward from goal to find required actions |
| **Blackboard**   | Agent's belief state                                |
| **Think**        | One cycle of goal selection + planning              |

---

## 11. References

- Jeff Orkin, "Three States and a Plan: The A.I. of F.E.A.R." (GDC 2006)
- Godot 4.x Documentation

---

## Appendix A: State Key Conventions

| Category     | Prefix  | Examples                      |
| ------------ | ------- | ----------------------------- |
| Agent status | (none)  | health, hunger, stamina       |
| Inventory    | has_    | has_food, has_weapon          |
| Location     | at_     | at_home, at_shop              |
| Target       | target_ | target_enemy, target_position |
| Flags        | is_     | is_hungry, is_in_combat       |

## Appendix B: Action Cost Guidelines

| Action Type   | Cost Range |
| ------------- | ---------- |
| Instant       | 0.5 - 1.0  |
| Quick (<1s)   | 1.0 - 2.0  |
| Medium (1-5s) | 2.0 - 5.0  |
| Long (>5s)    | 5.0 - 10.0 |
| Risky         | 10.0+      |

Lower costs = preferred by planner.
