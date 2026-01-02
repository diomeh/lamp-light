# GOAP + ECS + WorldState + SignalBus + Blackboard

## Authoritative Architecture Specification

Core Principle

Separate truth, belief, decision, execution, and transport.
No system may own more than one of these responsibilities.

## 1. Canonical Roles (Non-Negotiable)

### WorldState (Truth)

* Represents objective, authoritative facts about the simulation.
* Exists independently of agents.
* Contains only decision-relevant, semantic facts.
* Is data-only (no logic, no ECS, no GOAP).
* Is the single source of truth.

Examples:

* DoorOpen(Door42) = true
* FoodAt(LocationA) = true

WorldState:

* Does not track which agents know facts.
* Does not contain agent beliefs or memory.
* Does not react to goals or actions.

---

### Blackboard (Belief / Memory)

* Exists per agent.
* Represents what the agent believes to be true.
* Can be incomplete, stale, wrong, or forgotten.
* Is used only for planning.
* Is never authoritative.

Examples:

* Believes(FoodAt(LocationA))
* Believes(DoorOpen(Door42))
* LastSeen(Enemy, time)

Blackboard:

* Is updated only via Sensors or Action feedback.
* Never writes to WorldState.
* Never mirrors WorldState automatically.

---

### GOAP (Decision)

* Plans only against the Blackboard, never WorldState.
* Preconditions and effects are expressed only in belief terms.
* Produces Intents, not direct ECS calls.
* Replans when beliefs change or execution fails.

GOAP:

* Must not import ECS types.
* Must not read WorldState directly.
* Must treat Blackboard as stable during a planning cycle.

---

### ECS (Execution)

* Owns all simulation mechanics.
* Validates Intents against WorldState.
* Executes actions physically.
* Emits success/failure signals.
* Writes changes to WorldState.

ECS:

* Does not know about goals, planners, or beliefs.
* Does not mutate Blackboard.

### SignalBus (Transport Only)

* Transports events and intents.
* Stores no state.
* Contains no domain meaning.
* Can be replaced without breaking correctness.

SignalBus:

* Is edge-triggered, not level-triggered.
* Never used as state or memory.

## 2. Data Flow (Strict Directionality)

```
WorldState (truth)
   ↓ signals
Sensors (perception filtering)
   ↓
Blackboard (belief)
   ↓
GOAP (planning)
   ↓ intents
SignalBus
   ↓
ECS (execution)
   ↓
WorldState
```

No reverse dependencies allowed.

## 3. Sensors (Mandatory Layer)

* Sensors subscribe to SignalBus.
* Sensors apply perception rules:
   * Line of sight
   * Distance
   * Ownership
   * Faction
   * Access rights
   * Timing
* Sensors write beliefs to Blackboard.

Sensors:

* Never write to WorldState.
* Never expose WorldState directly to GOAP.

## 4. Action Lifecycle (Required)

1. GOAP plans using Blackboard snapshot.
2. GOAP emits an Intent.
3. ECS validates Intent against WorldState.
4. ECS executes or fails.
5. ECS emits success/failure signal.
6. Sensors update Blackboard based on result.
7. GOAP replans if required.

**Belief–truth mismatch is expected and required.**

## 5. State Semantics Rules

### WorldState

* “Would this still be true if all agents were deleted?”
   * Yes → WorldState
   * No → Not WorldState

### Blackboard

*  “Can two agents disagree about this?”
   *  Yes → Blackboard

## 6. Allowed Interactions

| From       | To                    | Allowed |
| ---------- | --------------------- | ------- |
| ECS        | WorldState            | YES     |
| ECS        | SignalBus             | YES     |
| SignalBus  | WorldState            | YES     |
| SignalBus  | Sensors               | YES     |
| Sensors    | Blackboard            | YES     |
| Blackboard | GOAP                  | YES     |
| GOAP       | SignalBus (Intents)   | YES     |
| GOAP       | ECS                   | NO      |
| GOAP       | WorldState            | NO      |
| Blackboard | WorldState            | NO      |
| SignalBus  | GOAP (domain meaning) | NO      |


## 7. Signal Design Rules

Signals:

* Indicate that something happened, not what it means.
* Must be domain-agnostic.

Bad:

* AgentNeedsFoodNow

Good:

* ComponentValueChanged(Hunger)
* ActionFailed(OpenDoor, Reason=Locked)

## 8. WorldState vs Blackboard Duplication (Intentional)

Duplication is **required** to enable:

* Fog of war
* Exploration
* Deception
* Memory
* Learning
* Emergence

Never attempt to “optimize away” belief duplication.

## 9. Planning Stability Rules

* GOAP plans against immutable Blackboard snapshots.
* WorldState changes invalidate plans via signals.
* Partial state updates during planning are forbidden.

## 10. Blacklist (Must Not Exist)

* GOAP reading ECS components
* GOAP reading WorldState
* Blackboard writing WorldState
* ECS knowing about goals
* SignalBus storing facts
* WorldState mirroring ECS 1:1
* Signals encoding planning semantics

## 11. Design Invariants (Enforce with Tests)

* WorldState = truth
* Blackboard = belief
* GOAP = decision
* ECS = execution
* SignalBus = transport
* Sensors = perception gate

Breaking any invariant re-introduces fragile coupling.

## Final Intent

* Agents plan based on what they believe.
* The world evolves based on what is true.
* Mismatch drives behavior, learning, and replanning.

This architecture is mandatory for correctness, scalability, and believable simulation behavior.
