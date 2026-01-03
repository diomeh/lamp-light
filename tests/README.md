# Test Suite

This directory contains all tests for the GOAP/ECS architecture.

## Structure

```
tests/
├── unit/              # Unit tests for individual components
│   ├── systems/
│   │   ├── goap/      # GOAP system tests
│   │   ├── ecs/       # ECS system tests
│   │   └── signal_bus/# SignalBus tests
│   └── negative/      # Tests that must fail (violation detection)
├── integration/       # Integration tests for system interactions
└── mocks/             # Mock implementations for testing
```

## Running Tests

### In Editor
1. Open GdUnit4 panel (bottom of editor)
2. Click "Run Tests"

### Headless (CI)
```bash
godot --headless -s res://addons/gdUnit4/runtests.gd
```

## Writing Tests

All test files must:
- Extend `GdUnitTestSuite`
- Start with `test_` prefix
- Use descriptive names
- Document architectural invariants being tested

## Test Categories

1. **Structural**: Enforce forbidden dependencies
2. **Interaction**: Validate allowed data flow
3. **Negative**: Ensure violations are caught

See `COMPLETE_TEST_EXAMPLES.md` for detailed examples.
