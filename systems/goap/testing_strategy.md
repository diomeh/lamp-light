# GOAP Testing Strategy

## Table of Contents

- [GOAP Testing Strategy](#goap-testing-strategy)
  - [Table of Contents](#table-of-contents)
  - [1. Overview](#1-overview)
    - [1.1 Purpose](#11-purpose)
    - [1.2 Testing Pyramid](#12-testing-pyramid)
    - [1.3 Testing Framework](#13-testing-framework)
    - [1.4 Philosophy](#14-philosophy)
  - [2. Test Organization](#2-test-organization)
    - [2.1 Directory Structure](#21-directory-structure)
    - [2.2 Naming Conventions](#22-naming-conventions)
  - [3. What to Test](#3-what-to-test)
    - [3.1 Unit Tests (per component)](#31-unit-tests-per-component)
    - [3.2 Feature Tests (integration)](#32-feature-tests-integration)
    - [3.3 End-to-End Tests](#33-end-to-end-tests)
  - [4. Test Fixtures](#4-test-fixtures)
    - [4.1 Mock Action](#41-mock-action)
    - [4.2 Mock Goal](#42-mock-goal)
    - [4.3 Test Helper](#43-test-helper)
  - [5. Performance Targets](#5-performance-targets)
    - [5.1 Test Speed](#51-test-speed)
    - [5.2 GOAP Performance](#52-goap-performance)
  - [6. Test Execution](#6-test-execution)
    - [6.1 Commands](#61-commands)
    - [6.2 CI/CD](#62-cicd)
  - [7. When to Add/Update Tests](#7-when-to-addupdate-tests)
  - [8. Test Review Checklist](#8-test-review-checklist)
  - [9. Common Patterns](#9-common-patterns)
    - [9.1 Async Action Testing](#91-async-action-testing)
    - [9.2 Plan Verification](#92-plan-verification)
    - [9.3 Performance Testing](#93-performance-testing)

## 1. Overview

### 1.1 Purpose

Testing strategy for the GOAP system covering unit tests, feature tests, and end-to-end tests.

### 1.2 Testing Pyramid

```plaintext
┌─────────────┐
│   E2E       │  ← Few, slow, high confidence
│   (5-10)    │
├─────────────┤
│   Feature   │  ← Medium count, integration
│   (20-30)   │
├─────────────┤
│   Unit      │  ← Many, fast, isolated
│   (50-100)  │
└─────────────┘
```

### 1.3 Testing Framework

**Primary:** GdUnit4

### 1.4 Philosophy

| Principle       | Description                                 |
| --------------- | ------------------------------------------- |
| **Isolation**   | Unit tests don't depend on other components |
| **Determinism** | Same results every run                      |
| **Speed**       | Fast feedback enables rapid iteration       |
| **Readability** | Tests serve as documentation                |

---

## 2. Test Organization

### 2.1 Directory Structure

```plaintext
tests/
└── goap/
    ├── unit/
    │   ├── test_goap_state.gd
    │   ├── test_goap_goal.gd
    │   ├── test_goap_action.gd
    │   ├── test_goap_planner.gd
    │   ├── test_goap_executor.gd
    │   ├── test_goap_orchestrator.gd
    │   └── test_goap_agent.gd
    ├── feature/
    │   ├── test_planning_scenarios.gd
    │   ├── test_execution_scenarios.gd
    │   ├── test_orchestration_scenarios.gd
    │   └── test_agent_lifecycle.gd
    ├── end2end/
    │   ├── test_npc_behaviors.gd
    │   └── test_multi_agent.gd
    ├── fixtures/
    │   ├── mock_action.gd
    │   ├── mock_goal.gd
    │   └── test_world.tscn
    └── helpers/
        └── goap_test_helper.gd
```

### 2.2 Naming Conventions

| Element     | Convention                               | Example                                      |
| ----------- | ---------------------------------------- | -------------------------------------------- |
| Test file   | `test_<component>.gd`                    | `test_goap_state.gd`                         |
| Test method | `test_<behavior>_<condition>_<expected>` | `test_get_value_missing_key_returns_default` |
| Fixture     | `mock_<type>.gd`                         | `mock_action.gd`                             |

---

## 3. What to Test

### 3.1 Unit Tests (per component)

| Component        | Key Behaviors                                            |
| ---------------- | -------------------------------------------------------- |
| GOAPState        | Get/set, signals on change, duplication, isolation       |
| GOAPGoal         | Satisfaction checking, priority calculation, relevance   |
| GOAPAction       | Regression logic, precondition checking, cost, lifecycle |
| GOAPPlanner      | Valid plans, optimal paths, edge cases, no-plan handling |
| GOAPExecutor     | Sequencing, success/failure signals, abort, state        |
| GOAPOrchestrator | Registration, budget enforcement, round-robin, timing    |
| GOAPAgent        | Goal selection, state machine, orchestrator integration  |

### 3.2 Feature Tests (integration)

| Category      | Focus                                                   |
| ------------- | ------------------------------------------------------- |
| Planning      | Realistic multi-step plans, cost optimization           |
| Execution     | State modification, failure handling, async             |
| Agent         | Lifecycle, goal selection, replan triggers              |
| Orchestration | Multi-agent fairness, budget limits, dynamic add/remove |

### 3.3 End-to-End Tests

| Category    | Focus                                                    |
| ----------- | -------------------------------------------------------- |
| NPC         | Complete behavior loops (e.g., hungry → find food → eat) |
| Multi-agent | Performance under load, no deadlocks, fairness           |

---

## 4. Test Fixtures

### 4.1 Mock Action

Configurable action for testing:

- Success/failure behavior
- Execution delay
- State modification
- Callback on execute

### 4.2 Mock Goal

Configurable goal for testing:

- Static or dynamic desires
- Static or dynamic priority
- Custom satisfaction logic

### 4.3 Test Helper

Utility functions:

- `create_goal(desires, priority)` — factory
- `create_action(name, preconditions, effects, cost)` — factory
- `create_agent_with_state(initial_state)` — setup
- `verify_plan_achieves_goal(plan, state, goal)` — validation
- `wait_for_signal_or_timeout(signal, timeout)` — async helper

---

## 5. Performance Targets

### 5.1 Test Speed

| Test Type  | Target | Maximum |
| ---------- | ------ | ------- |
| Unit       | < 5ms  | 10ms    |
| Feature    | < 50ms | 100ms   |
| E2E        | < 2s   | 5s      |
| Full suite | < 30s  | 60s     |

### 5.2 GOAP Performance

| Metric                    | Target  |
| ------------------------- | ------- |
| Plan generation (simple)  | < 1ms   |
| Plan generation (complex) | < 10ms  |
| Action execution overhead | < 0.1ms |
| Orchestrator per-frame    | < 4ms   |

---

## 6. Test Execution

### 6.1 Commands

```bash
# All GOAP tests
godot --headless --script addons/gdUnit4/bin/GdUnitCmdTool.gd --add tests/goap/

# By category
godot --headless --script addons/gdUnit4/bin/GdUnitCmdTool.gd --add tests/goap/unit/
godot --headless --script addons/gdUnit4/bin/GdUnitCmdTool.gd --add tests/goap/feature/
godot --headless --script addons/gdUnit4/bin/GdUnitCmdTool.gd --add tests/goap/end2end/
```

### 6.2 CI/CD

- Trigger: push, pull_request
- All unit and feature tests must pass
- E2E tests may run as separate job

---

## 7. When to Add/Update Tests

| Event         | Action                                   |
| ------------- | ---------------------------------------- |
| New component | Unit tests for public methods            |
| New feature   | Feature test for happy path + edge cases |
| Bug fix       | Regression test reproducing the bug      |
| API change    | Update affected tests                    |
| Refactor      | Verify existing tests pass               |

---

## 8. Test Review Checklist

- [ ] Deterministic (no random failures)
- [ ] Isolated (no shared state)
- [ ] Fast (within benchmarks)
- [ ] Clear name describing behavior
- [ ] Verifies one logical behavior
- [ ] Clean setup/teardown

---

## 9. Common Patterns

### 9.1 Async Action Testing

```plaintext
1. Create mock action with known timing
2. Execute plan
3. await signal with timeout
4. Verify final state
```

Don't use fixed delays; use signal-based waiting.

### 9.2 Plan Verification

```plaintext
1. Generate plan
2. Simulate execution to verify validity
3. Calculate total cost
4. Compare to known optimal (if determinable)
```

### 9.3 Performance Testing

```plaintext
1. Record start time (usec)
2. Execute operation
3. Assert elapsed < threshold
4. Allow tolerance for CI variability
```
