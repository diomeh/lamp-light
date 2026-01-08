# Test Suite

This directory contains all tests for the GOAP/ECS architecture.

## Structure

```plaintext
tests/
├── goap/
│   ├── unit
│   ├── integration
│   └── end2end
├── ecs/
│   ├── unit
│   ├── integration
│   └── end2end
└── ...
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
