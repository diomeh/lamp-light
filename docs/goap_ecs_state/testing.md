# GOAP / ECS / WorldState Architecture — Test Specification (Godot)

This document is an **authoritative, execution-oriented test specification**.
It defines **mandatory tests** that enforce architectural invariants for GOAP, ECS, WorldState, SignalBus, Sensors, and Blackboards.

Developers must **add or refactor tests** so that every invariant below is **provably enforced**.
If an invariant cannot be tested, it is considered **non-existent**.

---

## 1. Testing Goals (Non-Negotiable)

- Enforce **directional dependencies**
- Prevent **illegal coupling**
- Ensure **belief ≠ truth**
- Guarantee **planning stability**
- Make architectural violations fail the build

These tests validate **structure and data flow**, not gameplay correctness.

---

## 2. Required Test Framework

- Use **GdUnit4** as the primary test framework
- Tests must be runnable headless via CI:

```bash
godot --headless -s res://addons/gdUnit4/runtests.gd
```

---

## 3. Mandatory Test Categories

All invariants must be covered by **three test types**:

| Category | Purpose |
|--------|--------|
| Structural tests | Enforce forbidden references |
| Interaction tests | Enforce allowed data flow |
| Negative tests | Ensure illegal access fails |

---

## 4. Architectural Invariants to Enforce

### 4.1 Forbidden Dependencies (Structural Tests)

Tests must assert that the following **do not exist**:

- GOAP reading WorldState
- GOAP reading ECS components
- GOAP executing actions directly
- Blackboard writing WorldState
- ECS knowing about goals or planners
- SignalBus storing state or facts
- WorldState mirroring ECS 1:1

Example assertions:
- GOAP scripts do not reference `WorldState`
- GOAP instances do not hold `world_state` fields
- ECS instances do not reference planners
- Blackboard exposes no WorldState mutation methods

---

### 4.2 Allowed Dependency Graph (Interaction Tests)

The following data flow **must be enforced**:

```
WorldState → SignalBus → Sensors → Blackboard → GOAP → SignalBus → ECS → WorldState
```

Tests must fail if any edge outside this graph is observed.

### Connections:

The following connections are allowed

```
ECS → SignalBus.emit_signal()
WorldState → SignalBus.emit_signal()
SignalBus → Sensors (connect)
SignalBus → GOAP (ONLY for invalidation signals)
SignalBus → ECS (intent signals)
```

The following connections are forbidden

```
SignalBus → WorldState (direct mutation)
SignalBus → Blackboard (direct mutation)
SignalBus → GOAP (domain meaning)
```

---

## 5. SignalBus Tests

### Invariants

- SignalBus is **stateless**
- SignalBus transports events only
- SignalBus does not encode domain meaning

### Required Tests

- Emitting signals does not store state
- SignalBus contains no facts after multiple emits
- Signals do not mutate WorldState or Blackboard directly

### Allowed

* extends Node
* signal declarations
* No-op helper methods (optional, e.g. emit_* wrappers)

### Forbidden

* Member variables storing state
* Dictionaries, arrays, caches
* Game logic
* Conditional branching
* Timers
* References to WorldState, ECS, GOAP, Blackboard

---

## 6. Sensor Exclusivity Tests

### Invariants

- Sensors are the **only** allowed path from WorldState to Blackboard
- Sensors apply perception rules before writing beliefs

### Required Tests

- WorldState updates do not affect Blackboard without sensors
- Non-sensor systems attempting to write Blackboard fail
- Sensors correctly translate events into beliefs

---

## 7. Blackboard Tests (Belief vs Truth)

### Invariants

- Blackboard is **not authoritative**
- Blackboard does not auto-mirror WorldState
- Blackboard may contain incorrect or stale beliefs

### Required Tests

- WorldState changes do not update Blackboard automatically
- Two agents may hold conflicting beliefs
- Blackboard supports forgetting / decay (if implemented)

---

## 8. GOAP Planning Tests

### Invariants

- GOAP plans using **Blackboard snapshots only**
- GOAP never reads WorldState
- GOAP replans when beliefs change or execution fails

### Required Tests

- Planning fails without a Blackboard snapshot
- Snapshot immutability during planning
- Plans can succeed even when beliefs are wrong
- Plans are invalidated on action failure signals

---

## 9. Belief–Truth Mismatch Tests (Critical)

### Invariants

- Mismatch between belief and truth is expected
- Execution reconciles mismatch explicitly
- Mismatch triggers replanning

### Required Tests

- GOAP plans based on incorrect beliefs
- ECS rejects intent based on WorldState
- Failure signal updates Blackboard
- GOAP replans after mismatch

---

## 10. ECS Execution Tests

### Invariants

- ECS validates intents against WorldState
- ECS mutates WorldState only
- ECS emits success/failure signals

### Required Tests

- ECS rejects invalid intents
- ECS does not modify Blackboard
- ECS emits correct execution signals

---

## 11. Planning Stability Tests

### Invariants

- Planning uses immutable belief snapshots
- WorldState changes during planning do not affect the plan
- Plans are invalidated explicitly via signals

### Required Tests

- Blackboard mutation after snapshot does not alter current plan
- WorldState mutation invalidates plan via signal
- Partial updates do not affect in-progress planning

---

## 12. Negative Tests (Must Fail)

These tests must **explicitly assert failure**:

- GOAP planning without Blackboard
- Blackboard writing to WorldState
- ECS executing without intent
- SignalBus storing state
- GOAP accessing ECS components
- GOAP accessing WorldState

---

## 13. Test Harness Requirements

Developers must introduce:

- Test-only hooks (e.g. `_test_only_*`)
- Mock implementations:
  - WorldStateMock
  - BlackboardMock / Spy
  - SignalBusMock
  - ECSMock
- Dependency injection everywhere
- Hard failure on invariant violation

---

## 14. CI Enforcement Rule

- All architectural tests must run in CI
- Any invariant failure must fail the build
- No architectural invariant may exist without a test

---

## 15. Final Rule (Non-Negotiable)

**If an architectural invariant cannot be tested, it does not exist.**

These tests are mandatory to prevent architectural drift, coupling, and loss of emergent behavior.

Developers must treat this document as **executable intent**, not guidance.
Failure to comply will result in rejection of code changes until all tests are in place and passing.
